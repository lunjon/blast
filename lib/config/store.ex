defmodule Blast.ConfigStore do
  @moduledoc false
  # Used by the webapp to retrieve runtime configuration
  # such as base URL and requests from the spec.

  use Agent

  @me __MODULE__

  def start_link(_) do
    Agent.start(fn -> %{} end, name: @me)
  end

  def put(key, value) do
    Agent.update(@me, fn store ->
      Map.put(store, key, value)
    end)
  end

  @spec get(atom()) :: dynamic() | nil
  def get(key) do
    Agent.get(@me, fn store -> Map.get(store, key) end)
  end
end
