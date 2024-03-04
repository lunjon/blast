defmodule Blast.CLI do
  alias Blast.CLI.{Parser, Output}
  alias Blast.Worker.Config
  alias Blast.Manager
  alias Blast.Hooks
  require Logger

  def main(args) do
    parse_args(args)
    |> handle()
    |> Manager.kickoff()
    
    Process.sleep(:infinity)
  end

  @doc """
  Parses the arguments and returns a configuration
  containing the specfile, hooks, etc.
  """
  @spec parse_args([String.t()]) :: {:ok, Config.t()} | {:error, any()}
  def parse_args(args) do
    Parser.parse_args(args)
    |> handle()
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
    requests = Blast.Spec.get_requests(args.spec)
    hooks = load_hooks(args.hook_file)

    %Config{
      workers: args.workers,
      frequency: args.frequency,
      requests: requests,
      hooks: hooks
    }
  end

  defp load_hooks(nil), do: %Hooks{}

  defp load_hooks(filepath) do
    case Hooks.load_hooks(filepath) do
      {:ok, hooks} -> hooks
      {:error, reason} ->
        Output.error(reason)
        abort()
    end
  end

  @spec abort() :: no_return()
  defp abort() do
    System.halt(1)
  end
end
