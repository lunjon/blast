defmodule Blast.CLI do
  alias Blast.CLI.{Parser, Output}
  alias Blast.{Config, Hooks}
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
    %{spec: spec, hook_file: hook_file} = args

    hooks = load_hooks(hook_file)
    settings = spec.settings

    frequency = Map.get(args, :frequency, settings.frequency)

    config = %Config{
      frequency: frequency,
      requests: spec.requests,
      hooks: hooks
    }

    get_controller(args, config, spec.settings)
  end

  defp load_hooks(nil), do: %Hooks{}

  defp load_hooks(filepath) do
    {:ok, hooks} = Hooks.load_hooks(filepath)
    hooks
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
