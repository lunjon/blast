defmodule Blast.Controller.Default.Test do
  use ExUnit.Case
  alias Blast.{Collector, Config, Spec}

  setup do
    bucket = start_supervised!({Collector, :test})

    {:ok, spec} = Spec.load_file("test/blast.yml")
    config = %Config{
      frequency: 0,
      requests: spec.requests,
      bucket: bucket,
    }

    _pid = start_supervised!({Blast.Controller.Default, {10, config}})

    [bucket: bucket]
  end

  test("server starts workers", %{bucket: bucket}) do
    # Wait for initial results
    Process.sleep(2)
    prev = Collector.get(bucket)

    # Wait a little more
    Process.sleep(2)
    next = Collector.get(bucket)
    assert next.count > prev.count
  end
end
