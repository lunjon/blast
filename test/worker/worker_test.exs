defmodule BlastTest.Worker do
  use ExUnit.Case
  alias Blast.{Bucket, Spec, Worker, Hooks}
  alias Blast.Worker.Config

  setup :start_results
  setup :start_worker

  def start_results(_context) do
    {:ok, bucket} = Bucket.start_link(:test)
    [bucket: bucket]
  end

  def start_worker(%{bucket: bucket}) do
    {:ok, spec} = Spec.load_file("test/blast.yml")
    requests = Spec.get_requests(spec)

    {:ok, _} =
      Worker.start_link(%Config{
        frequency: 0,
        requests: requests,
        bucket: bucket,
        hooks: %Hooks{}
      })

    :ok
  end

  test "puts result", %{bucket: bucket} do
    results = Bucket.get(bucket)
    assert(map_size(results) > 0)
  end
end
