defmodule Blast.EndpointStats do
  @moduledoc """
  Contains statistics for a single endpoint.
  """
  alias __MODULE__, as: Self

  @type t :: %__MODULE__{
          # Total request count.
          count: integer(),
          # Average response time in milliseconds.
          average: float(),
          # Minimum response time in milliseconds.
          min: integer(),
          # Maximum response time in milliseconds.
          max: integer()
        }

  defstruct count: 1,
            average: 0,
            min: 0,
            max: 0

  # Updates global stats:
  #   - request count
  #   - min, max and average response times
  def update(%Self{min: min, max: max} = stats, duration) do
    stats =
      if duration < min do
        Map.put(stats, :min, duration)
      else
        stats
      end

    if duration > max do
      Map.put(stats, :max, duration)
    else
      stats
    end
    |> update_in(
      [Access.key!(:count)],
      fn count -> count + 1 end
    )
    |> update_in(
      [Access.key!(:average)],
      fn average -> (average + duration) / 2.0 end
    )
  end
end
