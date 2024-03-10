defmodule BlastTest.Worker do
  use ExUnit.Case
  alias Blast.{Bucket, Spec, Worker, Hooks}
  alias Blast.Worker.Config

  setup :start_results_bucket
  setup :start_worker

  def start_results_bucket(_context) do
    bucket = start_supervised!({Bucket, :test})
    [bucket: bucket]
  end

  def start_worker(%{bucket: bucket}) do
    {:ok, spec} = Spec.load_file("test/blast.yml")

    requests = Spec.get_requests(spec)

    config = %Config{
      frequency: 0,
      requests: requests,
      bucket: bucket,
      hooks: %Hooks{}
    }

    {:ok, _} = start_supervised({Worker, config})
    :ok
  end

  test("puts result", %{bucket: bucket}) do
    # Act: wait for some requests
    Process.sleep(2)
    results = Bucket.get(bucket)

    # Assert
    assert results.count > 0
    prev_count = results.count

    # Act: wait a little more
    Process.sleep(4)
    results = Bucket.get(bucket)
    assert results.count > prev_count
  end
end
