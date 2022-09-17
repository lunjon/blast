defmodule Blast.CLI do
  alias Blast.CLI.Parser
  require Logger

  def main(args) do
    try do
      Parser.parse_args(args)
      |> handle()
    rescue
      e ->
        msg = Exception.format(:error, e)
        Logger.error(msg)
        IO.puts(:stderr, msg)
        System.stop(1)
    end
  end

  defp handle({:error, msg}) do
    IO.puts(:stderr, "error: #{msg}")
    System.stop(1)
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    System.stop(1)
  end

  defp handle({:ok, args}) do
    if not args.verbose do
      Logger.configure(level: :none)
    else
      Logger.configure(level: :info)
    end

    Logger.debug("Args: #{inspect(args)}")

    case args.connect do
      "" ->
        req = %HTTPoison.Request{
          method: args.method,
          url: args.url,
          headers: args.headers,
          body: args.body
        }

        run(:manager, req, args)

      node_name ->
        run(:worker, String.to_atom(node_name))
    end
  end

  defp run(:manager, req, args) do
    # Start this as a manager node, allowing other nodes connecting
    # as workers in a distributed cluster: Node.connect(:manager@localhost)
    Node.start(:manager@localhost)

    children = [
      Blast.Results,
      Blast.WorkerSupervisor,
      {Blast.Manager, {req, args.workers, self()}}
    ]

    opts = [strategy: :one_for_all, name: Blast.Supervisor]
    Supervisor.start_link(children, opts)

    receive do
      {:done} ->
        Logger.info("Received done")
    after
      args.duration ->
        Logger.info("Stopping workers...")
        Blast.Manager.stop_all()
    end

    Blast.Results.get()
    |> Blast.Format.format_result(:json)
    |> IO.puts()
  end

  defp run(:worker, manager_node) do
    # Start this as a worker node.
    Node.start(:worker@localhost)

    children = [
      Blast.Results,
      Blast.WorkerSupervisor
    ]

    Logger.info("Starting worker, connecting to manager node: #{manager_node}")

    case Node.connect(:manager@localhost) do
      n when n in [:ignored, false] ->
        IO.puts(:stderr, "failed to connect to manager node")
        System.stop(1)

      _ ->
        Logger.info("Connected successfully to manager node")
    end

    opts = [strategy: :one_for_all, name: Blast.Supervisor]
    Supervisor.start_link(children, opts)

    receive do
      {:done} -> Logger.info("Received done")
    end
  end
end
