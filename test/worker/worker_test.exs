defmodule BlastTest.Worker.SampleSpec do
  def base_url(), do: "https://cats.meow"

  def requests() do
    [
      %{
        method: "get",
        path: "/facts"
      },
      %{
        method: "post",
        path: "/cats"
      }
    ]
  end
end

defmodule BlastTest.Worker do
  use ExUnit.Case
  alias Blast.{Collector, Config, Spec, Worker, Hooks}

  setup :start_results_bucket
  setup :start_worker

  def start_results_bucket(_context) do
    bucket = start_supervised!({Collector, :test})
    [bucket: bucket]
  end

  def start_worker(%{bucket: bucket}) do
    {:ok, spec} = Spec.load(BlastTest.Worker.SampleSpec)

    config = %Config{
      frequency: 0,
      requests: spec.requests,
      bucket: bucket,
      hooks: %Hooks{}
    }

    {:ok, _} = start_supervised({Worker, config})

    :ok
  end

  test("puts result", %{bucket: bucket}) do
    # Act: wait for some requests
    Process.sleep(2)
    results = Collector.get(bucket)

    # Assert
    assert results.count > 0
    prev_count = results.count

    # Act: wait a little more
    Process.sleep(4)
    results = Collector.get(bucket)
    assert results.count > prev_count
  end
end
