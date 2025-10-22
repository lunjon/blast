defmodule Blast.IntegrationTest do
  use ExUnit.Case

  @moduledoc """
  This module tests multiple components of Blast:
  - ConfigStore
  - Orchestrator
  - Controller
  - Worker

  It tests that, once started, they all communicate properly
  and that requests are sent and responses are registered.

  The requests targets the test server.
  """

  alias Blast.Orchestrator
  alias Blast.Config

  setup_all(_) do
    {:ok, config} = Config.load(Blast.IntegrationTest.Blastfile, %{frequency: 100})

    _ = start_supervised!({Blast.ConfigStore, config})
    _ = start_supervised!({Blast.Orchestrator, config})
    _ = start_supervised!({Blast.Controller.Default, config})
    _ = start_supervised!({Plug.Cowboy, scheme: :http, plug: BlastTest.TestServer, port: 13001})

    :ok
  end

  test("blast runs", _context) do
    # Arrange: start blast and wait for initial results.
    Orchestrator.start()
    Process.sleep(50)

    # Act: get state
    state = Orchestrator.get_state()
    count_before = state.total

    # Wait a little more
    Process.sleep(50)
    state = Orchestrator.get_state()
    assert state.total > count_before

    # Act: stop and get current state
    :ok = Orchestrator.stop()
    state = Orchestrator.get_state()
    count_stopped = state.total

    # Assert that no requests are being sent after app controller was stopped
    Process.sleep(50)
    state = Orchestrator.get_state()
    assert state.total === count_stopped
  end
end

defmodule Blast.IntegrationTest.Blastfile do
  use Blastfile

  def base_url(), do: "http://localhost:13001"

  # See endpoints below in the test server.
  def requests() do
    [%{method: "get", path: "/ok"}]
  end
end
