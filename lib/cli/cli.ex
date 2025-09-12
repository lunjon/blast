defmodule Blast.CLI do
  alias Blast.Orchestrator
  alias Blast.CLI.{Parser, Output}
  alias Blast.Config
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

    # Hang the process otherwise it will exit from the main process.
    Process.sleep(:infinity)
  end

  defp handle({:error, msg}) do
    Output.error(msg)
    abort()
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    abort()
  end

  # TODO: refactor most of this function to another module.
  # It could be useful for instance when testing and starting `iex -S mix`.
  defp handle({:ok, args}) do
    %{blastfile: filepath} = args
    module = load_blast_module(filepath)

    config =
      case Config.load(module, args) do
        {:ok, config} ->
          config

        {:error, err} ->
          Logger.error("Error loading module: #{err}")
          Output.error("failed to load module: #{err}")
          abort()
      end

    {:ok, _} = Supervisor.start_child(@supervisor, {Blast.ConfigStore, config})

    # Start the Orchestrator and Controller
    {:ok, _} = Supervisor.start_child(@supervisor, {Orchestrator, config})

    controller = get_controller(config)
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

  @spec get_controller(Config.t()) :: {module(), any()}
  defp get_controller(config) do
    case config.settings.control.kind do
      :default ->
        {Blast.Controller.Default, config}

      :rampup ->
        {Blast.Controller.Rampup, config}
    end
  end

  @spec abort() :: no_return()
  defp abort() do
    System.halt(1)
  end
end
