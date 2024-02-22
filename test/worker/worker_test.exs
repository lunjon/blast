defmodule BlastTest.Worker do
  use ExUnit.Case
  alias Blast.Bucket
  alias Blast.Worker
  alias Blast.Worker.Config
  alias Blast.Spec

  setup :start_results
  setup :start_worker

  def start_results(_context) do
    {:ok, bucket} = Bucket.start_link(:test)
    [bucket: bucket]
  end

  def start_worker(%{bucket: bucket}) do
    {:ok, spec} = Spec.load_file("test/blast.yml")
    requests = Spec.get_requests(spec)
    config = %Config{frequency: 0, requests: requests, bucket: bucket}
    {:ok, _} = Worker.start_link(config)
    :ok
  end

  test "puts result", %{bucket: bucket} do
    results = Bucket.get(bucket)
    assert(map_size(results) > 0)
  end
end
