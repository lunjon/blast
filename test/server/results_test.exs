defmodule BlastTest do
  use ExUnit.Case
  alias Blast.Results

  @url "https://localhost/path"

  setup_all do
    {:ok, _} = Results.start_link(:no_args)
    :ok
  end

  test "puts new result" do
    # Arrange
    1..10
    |> Enum.each(fn _ -> Results.put(@url, 200) end)

    # Assert
    results = Results.get()
    assert Map.get(results, @url) > 0
  end
end
