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

    _ = start_supervised!({Blast.AppState, spec})
    _ = start_supervised!({Blast.Controller.Default, {5, config}})

    :ok
  end

  test("server starts workers", _context) do
    # Arrange: start blast and wait for initial results
    AppState.start()
    Process.sleep(10)

    # Act: get stats
    stats = AppState.get_stats()

    # Wait a little more
    Process.sleep(20)
    stats = AppState.get_stats() |> IO.inspect()
    assert stats
  end
end

defmodule Blast.IntegrationTest.Blastfile do
  def base_url(), do: ""

  def requests() do
    [%{method: "get", path: "/"}]
  end
end
