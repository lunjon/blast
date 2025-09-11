alias Blast.Orchestrator

defmodule Starter do
  @doc """
  Starts the rest of the servers required by the runtime.
  This is sort of a hack since it uses the CLI directly.

  Make sure that you're running a local server at the correct port.
  """
  def start() do
    spawn(fn ->
      Blast.CLI.main(["--blastfile", "examples/basic.ex"])
      IO.puts("Use Orchestrator.start() to start the blasting.")
      IO.puts("Use Orchestrator.stop() to stop the blasting.")
    end)
  end
end
