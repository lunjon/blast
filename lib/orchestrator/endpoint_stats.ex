defmodule Blast.EndpointStats do
  @moduledoc """
  Contains statistics for a single endpoint.
  """
  alias __MODULE__, as: Self

  @typedoc """
  Tracks the statistics for a single endpoint (HTTP method + path).

  Statuses are a map of status code to count.
  """
  @type t :: %__MODULE__{
          # Total request count.
          count: integer(),
          # Average response time in milliseconds.
          average: float(),
          # Minimum response time in milliseconds.
          min: integer(),
          # Maximum response time in milliseconds.
          max: integer(),
          # All unique HTTP status codes this endpoint has responded with.
          statuses: %{integer() => integer()}
        }

  defstruct count: 0,
            average: 0,
            min: 0,
            max: 0,
            statuses: %{}

  @doc """
  Updates stats for this endpoint:
    - request count
    - min, max and average response times
    - Status codes
  """
  @spec update(t(), number(), non_neg_integer()) :: t()
  def update(%Self{min: min, max: max} = stats, duration, status) do
    stats =
      if duration < min do
        Map.put(stats, :min, duration)
      else
        stats
      end

    stats =
      if duration > max do
        Map.put(stats, :max, duration)
      else
        stats
      end

    stats
    |> update_in(
      [Access.key!(:count)],
      fn count -> count + 1 end
    )
    |> update_in(
      [Access.key!(:average)],
      fn average -> (average + duration) / 2.0 end
    )
    |> update_in(
      [Access.key!(:statuses), status],
      fn
        nil -> 1
        count -> count + 1
      end
    )
  end
end
