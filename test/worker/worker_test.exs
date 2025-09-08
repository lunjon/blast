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

  setup(_) do
    bucket = start_supervised!({Collector, :test})
    {:ok, spec} = Spec.load(BlastTest.Worker.SampleSpec)

    config = %Config{
      requests: spec.requests,
      bucket: bucket,
      hooks: %Hooks{},
      settings: spec.settings
    }

    _ = start_supervised!({Worker, config})
    [bucket: bucket]
  end

  test("puts result", %{bucket: bucket}) do
    # Act: wait for some requests
    Process.sleep(50)
    results = Collector.get(bucket)

    # Assert
    assert results.count > 0
    prev_count = results.count

    # Act: wait a little more
    Process.sleep(50)
    results = Collector.get(bucket)

    # Assert
    assert results.count > prev_count
  end
end
