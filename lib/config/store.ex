defmodule Blast.ConfigStore do
  @moduledoc false

  # This is used to retrieve the configuration dynamically
  # since it may be re-configured during runtime from the
  # web interface.

  use Agent
  alias Blast.Config

  @me __MODULE__

  def start_link(config) do
    Agent.start(fn -> config end, name: @me)
  end

  @doc """
  Return the configuration.
  """
  @spec get() :: Config.t()
  def get() do
    Agent.get(@me, fn config -> config end)
  end

  @doc """
  Update the number of workers in the configuration.
  """
  @spec set_workers(non_neg_integer()) :: :ok
  def set_workers(count) when count > 0 and count < 5000 do
    Agent.update(@me, fn config ->
      Map.update(config, :workers, count, fn _ -> count end)
    end)
  end
end
