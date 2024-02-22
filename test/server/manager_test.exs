defmodule BlastTest.Manager do
  use ExUnit.Case
  alias Blast.Manager
  alias Blast.Worker.Config
  alias Blast.Spec

  setup :start_manager
  setup :config

  def start_manager(_context) do
    {:ok, pid} = Manager.start_link(:test)
    on_exit(fn -> Process.exit(pid, :kill) end)
    [pid: pid]
  end

  def config(_context) do
    {:ok, spec} = Spec.load_file("test/blast.yml")
    requests = Spec.get_requests(spec)
    config = %Config{workers: 1, frequency: 1, requests: requests}
    [config: config]
  end

  test "starts in idle mode", %{pid: pid} do
    :idle = Manager.get_status(pid)
  end

  test "kickoff() starts manager if idle", %{pid: pid, config: config} do
    :idle = Manager.get_status(pid)
    Manager.kickoff(config, pid)
    :running = Manager.get_status(pid)
  end

  test "kickoff() does nothing if already running", %{pid: pid, config: config} do
    # Arrange
    Manager.kickoff(config, pid)
    :running = Manager.get_status(pid)

    # Act & assert
    Manager.kickoff(config, pid)
    :running = Manager.get_status(pid)
  end

  test "stop changes status", %{pid: pid, config: config} do
    Manager.kickoff(config)
    Manager.stop_all(pid)
    :idle = Manager.get_status(pid)
  end
end
