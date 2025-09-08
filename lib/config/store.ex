defmodule Blast.ConfigStore do
  @moduledoc false
  # Used by the server to get runtime configuration
  # such as base URL and requests.

  use Agent
  alias Blast.Config

  @me __MODULE__

  def start_link(config) do
    Agent.start(fn -> config end, name: @me)
  end

  @spec get() :: Config.t()
  def get() do
    Agent.get(@me, fn config -> config end)
  end
end
