defmodule CoreTest.Worker do
  use ExUnit.Case
  alias Core.Results
  alias Core.Worker
  alias Core.WorkerConfig

  @url "https://localhost/path"

  setup_all do
    {_, _} = Results.start_link(:no_args)
    request = %HTTPoison.Request{url: @url, method: "GET"}
    config = %WorkerConfig{frequency: 1, request: request}
    {:ok, pid} = Worker.start_link(config)
    [pid: pid]
  end

  test "puts new result", %{pid: pid} do
    assert(Process.alive?(pid))
  end
end
