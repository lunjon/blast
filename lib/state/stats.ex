defmodule Blast.Stats do
  @moduledoc """
  This module contains statistics for a current running blast.
  """

  alias Blast.EndpointStats
  alias HTTPoison.Response
  alias __MODULE__, as: Self

  @type t :: %__MODULE__{
          # Total request count.
          total: integer(),
          status_counts: %{integer() => integer()},
          endpoints: %{String.t() => EndpointStats.t()}
        }

  defstruct total: 0,
            status_counts: %{},
            endpoints: %{}

  @spec add_response(t(), integer(), Response.t()) :: t()
  def add_response(stats, duration, %Response{} = res) do
    %Response{
      request: request,
      request_url: url,
      status_code: status_code
    } = res

    %URI{path: path} = URI.parse(url)
    method = to_string(request.method) |> String.upcase()
    endpoint = "#{method} #{path}"

    update_in(
      stats,
      [Access.key!(:total)],
      &(&1 + 1)
    )
    |> update_status_counts(status_code)
    |> update_endpoint(endpoint, duration)
  end

  defp update_status_counts(stats, status_code) do
    update_in(
      stats,
      [Access.key!(:status_counts), status_code],
      fn count ->
        case count do
          nil -> 1
          n -> n + 1
        end
      end
    )
  end

  defp update_endpoint(stats, endpoint, duration) do
    update_in(
      stats,
      [Access.key!(:endpoints), endpoint],
      fn value ->
        case value do
          nil -> %EndpointStats{average: duration, min: duration, max: duration, count: 1}
          st -> EndpointStats.update(st, duration)
        end
      end
    )
  end
end

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

  defstruct count: 0,
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
