defmodule Blast.Collector.Test do
  use ExUnit.Case
  alias Blast.Collector

  @url "https://localhost/path"

  setup(_context) do
    pid = start_supervised!({Collector, :test})
    [pid: pid]
  end

  test "puts new result", %{pid: pid} do
    # Arrange
    res = build_res()

    for ii <- 1..10 do
      :ok = Collector.put(ii, res, pid)
    end

    # Assert
    results = Collector.get(pid)
    assert results.responses[@url] > 0
  end

  defp build_res(status \\ 200) do
    %HTTPoison.Response{
      request_url: @url,
      request: %{method: :get},
      status_code: status
    }
  end
end
