defmodule Blast.IntegrationTest do
  @moduledoc """
  This module tests multiple components of Blast:
  - AppState
  - Controller
  - Worker

  It tests that, once started, they all communicate properly
  and that requests are sent and responses are registered.
  """
  alias Blast.AppState
  alias Blast.Hooks
  alias Blast.Config

  use ExUnit.Case

  setup_all(_) do
    {:ok, spec} = Blast.Spec.load(Blast.IntegrationTest.Blastfile)

    config = %Config{
      hooks: %Hooks{},
      requests: spec.requests,
      settings: spec.settings
    }

    worker_count = 2
    _ = start_supervised!({Blast.AppState, spec})
    _ = start_supervised!({Blast.Controller.Default, {worker_count, config}})

    :ok
  end

  test("server starts workers", _context) do
    # Arrange: start blast and wait for initial results
    AppState.start()
    Process.sleep(20)

    # Act: get stats
    stats = AppState.get_stats()
    count_before = stats.total

    # Wait a little more
    Process.sleep(20)
    stats = AppState.get_stats()
    assert stats.total > count_before

    # Act: stop and get current stats
    :ok = AppState.stop()
    stats = AppState.get_stats()
    count_stopped = stats.total

    # Assert that no requests are being sent after app controller was stopped
    Process.sleep(20)
    stats = AppState.get_stats()
    assert stats.total === count_stopped
  end
end

defmodule Blast.IntegrationTest.Blastfile do
  def base_url(), do: ""

  def requests() do
    [%{method: "get", path: "/"}]
  end

  def settings(), do: %{frequency: 100}
end
