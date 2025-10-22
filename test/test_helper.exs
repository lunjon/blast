defmodule Probe.Mock do
  @behaviour Blast.Probe

  @impl Blast.Probe
  def probe(_url), do: :ok
end

# Register the probe mock.
Application.put_env(:blast, :probe, Probe.Mock)

require Logger
Logger.configure(level: :none)

ExUnit.start()
