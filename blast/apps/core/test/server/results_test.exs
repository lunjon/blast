defmodule BlastTest.Results do
  use ExUnit.Case
  alias Blast.Results

  @url "https://localhost/path"

  setup_all do
    Results.start_link(:test)
    :ok
  end

  test "puts new result" do
    res = %HTTPoison.Response{
      request_url: @url,
      status_code: 200
    }

    # Arrange
    1..10
    |> Enum.each(fn _ -> Results.put(res) end)

    # Assert
    results = Results.get()
    assert Map.get(results, @url) > 0
  end
end
