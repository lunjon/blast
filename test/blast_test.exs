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
  """

  alias Blast.Orchestrator
  alias Blast.Config

  setup_all(_) do
    {:ok, config} = Config.load(Blast.IntegrationTest.Blastfile, %{frequency: 100})

    _ = start_supervised!({Blast.ConfigStore, config})
    _ = start_supervised!({Blast.Orchestrator, config})
    _ = start_supervised!({Blast.Controller.Default, config})

    :ok
  end

  test("server starts workers", _context) do
    # Arrange: start blast and wait for initial results
    Orchestrator.start()
    Process.sleep(20)

    # Act: get stats
    stats = Orchestrator.get_stats()
    count_before = stats.total

    # Wait a little more
    Process.sleep(20)
    stats = Orchestrator.get_stats()
    assert stats.total > count_before

    # Act: stop and get current stats
    :ok = Orchestrator.stop()
    stats = Orchestrator.get_stats()
    count_stopped = stats.total

    # Assert that no requests are being sent after app controller was stopped
    Process.sleep(20)
    stats = Orchestrator.get_stats()
    assert stats.total === count_stopped
  end
end

defmodule Blast.IntegrationTest.Blastfile do
  def base_url(), do: ""

  def requests() do
    [%{method: "get", path: "/"}]
  end
end
