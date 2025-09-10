defmodule Blast.IntegrationTest do
  @moduledoc """
  This module tests multiple components of Blast:
  - AppState
  - Controller
  - Worker

  It tests that, once started, they all communicate properly
  and that requests are sent and responses are registered.
  """

  use ExUnit.Case

  setup_all(_) do
  end
end
