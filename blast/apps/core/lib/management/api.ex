defmodule Core.Management.API do
  use Task
  require Logger
  alias Core.Management.Handler

  @supervisor Blast.TaskSupervisor

  def start_link(port) do
    Task.start_link(__MODULE__, :run, [port])
  end

  def run(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Client connected")
    {:ok, pid} = Task.Supervisor.start_child(@supervisor, fn -> Handler.serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    accept(socket)
  end
end
