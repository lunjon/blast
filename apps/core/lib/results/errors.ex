defmodule Core.Results.Error do
  def handle_error(nil), do: :ok

  def handle_error(error) do
    case error do
      %HTTPoison.Error{reason: :econnrefused} ->
        IO.puts(:stderr, "unreachable endpoint configured: exiting")
        System.halt(1)
    end
  end
end
