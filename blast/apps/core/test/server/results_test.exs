defmodule CoreTest.Bucket do
  use ExUnit.Case
  alias Core.Bucket

  @url "https://localhost/path"

  setup :start_results

  def start_results(_context) do
    {:ok, pid} = Bucket.start_link(:test)
    on_exit(fn -> Process.exit(pid, :kill) end)
    [pid: pid]
  end

  test "puts new result", %{pid: pid} do
    res = %HTTPoison.Response{
      request_url: @url,
      status_code: 200
    }

    # Arrange
    1..10
    |> Enum.each(fn _ -> Bucket.put(res, pid) end)

    # Assert
    results = Bucket.get(pid)
    assert Map.get(results, @url) > 0
  end
end
