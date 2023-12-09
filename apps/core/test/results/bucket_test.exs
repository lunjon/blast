defmodule BlastTest.Bucket do
  use ExUnit.Case
  alias Blast.Bucket

  @url "https://localhost/path"

  setup(_context) do
    {:ok, pid} = Bucket.start_link(:test)
    on_exit(fn -> Process.exit(pid, :kill) end)
    [pid: pid]
  end

  test "puts new result", %{pid: pid} do
    # Arrange
    res = build_res()

    for _ <- 1..10 do
      :ok = Bucket.put(res, pid)
    end

    # Assert
    results = Bucket.get(pid)
    assert results.responses[@url] > 0
  end

  defp build_res(status \\ 200) do
    %HTTPoison.Response{
      request_url: @url,
      status_code: status
    }
  end
end
