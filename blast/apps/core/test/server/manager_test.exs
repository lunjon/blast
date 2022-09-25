defmodule CoreTest.Manager do
  use ExUnit.Case
  alias Core.Manager
  alias Core.Worker.Config

  setup :start_manager
  setup :config

  def start_manager(_context) do
    {:ok, pid} = Manager.start_link(nil, :test)
    on_exit(fn -> Process.exit(pid, :kill) end)
    [pid: pid]
  end

  def config(_context) do
    request = %HTTPoison.Request{url: ""}
    config = %Config{workers: 1, frequency: 1, request: request}
    [config: config]
  end

  test "starts in idle mode", %{pid: pid} do
    :idle = Manager.get_status(pid)
  end

  test "kickoff changes status", %{pid: pid, config: config} do
    Manager.kickoff(config, pid)
    :running = Manager.get_status(pid)
  end

  test "stop changes status", %{pid: pid, config: config} do
    Manager.kickoff(config)
    Manager.stop_all(pid)
    :idle = Manager.get_status(pid)
  end
end
