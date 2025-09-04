defmodule Blast.CLI do
  alias Blast.CLI.{Parser, Output}
  alias Blast.{Config, Hooks, Spec}
  alias Blast.Spec.Settings
  require Logger

  @supervisor Blast.Supervisor

  @doc """
  The main entrypoint for the application and/or escript.

  It parses the arguments and returns a configuration
  containing the specfile, hooks, etc.
  """
  def main(args) do
    Parser.parse_args(args)
    |> handle()
    |> start()
  end

  defp start(child) do
    Logger.info("====== STARTING NEW BLAST ======")
    {:ok, _} = Supervisor.start_child(@supervisor, child)
  end

  defp handle({:error, msg}) do
    Output.error(msg)
    abort()
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    abort()
  end

  defp handle({:ok, args}) do
    %{blastfile: filepath} = args
    module = load_blast_module(filepath)

    spec =
      case Spec.load(module) do
        {:ok, spec} ->
          spec

        {:error, err} ->
          Logger.error("Error loading module: #{err}")
          Output.error("failed to load module: #{err}")
          abort()
      end

    {:ok, hooks} = Hooks.load(module)

    probe(spec.base_url)

    settings = spec.settings
    frequency = Map.get(args, :frequency, settings.frequency)

    config = %Config{
      frequency: frequency,
      requests: spec.requests,
      hooks: hooks
    }

    Logger.info("Config: #{inspect(config)}")
    get_controller(args, config, spec.settings)
  end

  defp load_blast_module(filepath) do
    case Code.require_file(filepath, ".") do
      [{module, _}] ->
        module

      mods ->
        Output.error(
          "The blastfile must contain exactly one Elixir module - found #{length(mods)}"
        )

        abort()
    end
  end

  # Check if we can connect to the host+port with TCP.
  defp probe(url) do
    %URI{host: host, port: port} = URI.parse(url)

    host = String.to_charlist(host)

    case :gen_tcp.connect(host, port, []) do
      {:ok, socket} ->
        Logger.debug("Successfully connected to #{host}:#{port}")
        :gen_tcp.close(socket)

      {:error, reason} ->
        Output.error("failed to connect to #{host}:#{port}: #{inspect(reason)}")
        Logger.error("Failed to connect to #{host}:#{port}: #{inspect(reason)}")
        abort()
    end
  end

  @spec get_controller(map(), Config.t(), Settings.t()) :: {module(), any()}
  defp get_controller(args, config, %Settings{control: control}) do
    %{kind: kind, props: props} = control

    case kind do
      :default -> {Blast.Controller.Default, {args.workers, config}}
      :rampup -> {Blast.Controller.Rampup, {config, props}}
    end
  end

  @spec abort() :: no_return()
  defp abort() do
    System.halt(1)
  end
end
