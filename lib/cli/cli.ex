defmodule Blast.CLI do
  alias Blast.CLI.{Parser, Output}
  alias Blast.{Config, Hooks, Spec}
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

    # Hang the process otherwise it will exit from the main process.
    Process.sleep(:infinity)
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
      case Spec.load(module, frequency: Map.get(args, :frequency)) do
        {:ok, spec} ->
          spec

        {:error, err} ->
          Logger.error("Error loading module: #{err}")
          Output.error("failed to load module: #{err}")
          abort()
      end

    {:ok, hooks} = Hooks.load(module)

    probe(spec.base_url)

    # Initialize the controller
    config = %Config{
      settings: spec.settings,
      requests: spec.requests,
      hooks: hooks,
      bucket: nil
    }

    # Register dynamic configuration

    controller = get_controller(args, spec, config)
    {:ok, _} = Supervisor.start_child(@supervisor, controller)
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
        Logger.info("Successfully connected to #{host}:#{port}")
        :gen_tcp.close(socket)

      {:error, reason} ->
        Output.error("failed to connect to #{host}:#{port}: #{inspect(reason)}")
        Logger.error("Failed to connect to #{host}:#{port}: #{inspect(reason)}")
        abort()
    end
  end

  @spec get_controller(map(), Spec.t(), Config.t()) :: {module(), any()}
  defp get_controller(args, spec, config) do
    %{kind: kind, props: props} = spec.settings

    case kind do
      :default -> {Blast.Controller.Default, {args.workers, config}}
      :rampup -> {Blast.Controller.Rampup, {props, config}}
    end
  end

  @spec abort() :: no_return()
  defp abort() do
    System.halt(1)
  end
end
