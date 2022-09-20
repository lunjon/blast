defmodule BlastTest.Worker do
  use ExUnit.Case
  alias Blast.Results
  alias Blast.Worker
  alias Blast.WorkerConfig

  @url "https://localhost/path"

  setup_all do
    {_, _} = Results.start_link(:no_args)
    request = %HTTPoison.Request{url: @url, method: "GET"}
    config = %WorkerConfig{frequency: 1}
    {:ok, pid} = Worker.start_link({request, config})
    [pid: pid]
  end

  test "puts new result", %{pid: pid} do
    assert(Process.alive?(pid))
  end
end
