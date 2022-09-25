defmodule CoreTest.Worker do
  use ExUnit.Case
  alias Core.Results
  alias Core.Worker
  alias Core.Worker.Config

  @url "https://localhost/path"

  setup :start_results
  setup :start_worker

  def start_results(_context) do
    {:ok, bucket} = Results.start_link(:test)
    [bucket: bucket]
  end

  def start_worker(%{bucket: bucket}) do
    request = %HTTPoison.Request{url: @url, method: "GET"}
    config = %Config{frequency: 0, request: request, results_bucket: bucket}
    {:ok, _} = Worker.start_link(config)
    :ok
  end

  test "puts result", %{bucket: bucket} do
    results = Results.get(bucket)
    assert(map_size(results) > 0)
  end
end
