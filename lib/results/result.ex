defmodule Blast.Result do
  alias HTTPoison.Response
  alias __MODULE__

  @moduledoc """
  Container for responses collected during a load test run.

  Responses are group per URL and status code. This means that
  each response has a URL which maps to a status count.
  """

  @type t :: %__MODULE__{
          # Total request count
          count: integer(),
          # Average response time in milliseconds
          average: float(),
          # Minimum response time in milliseconds
          min: integer(),
          # Maximum response time in milliseconds
          max: integer(),
          # Tracks stats for the different endpoints (method + url)
          responses: map()
        }

  defstruct count: 0,
            average: 0,
            min: 0,
            max: 0,
            responses: %{}

  @spec add_response(t(), integer(), Response.t()) :: t()
  def add_response(result, duration, %Response{} = res) do
    %Response{
      request: request,
      request_url: url,
      status_code: status
    } = res

    method = to_string(request.method) |> String.upcase()
    endpoint = "#{method} #{url}"

    result
    |> update_status(status, endpoint)
    |> update_stats(duration)
  end

  defp update_status(result, status, endpoint) do
    update_in(
      result,
      [Access.key!(:responses), endpoint],
      fn value ->
        case value do
          nil -> %{status => 1}
          statuses -> Map.update(statuses, status, 1, &(&1 + 1))
        end
      end
    )
  end

  # Updates global stats:
  #   - request count
  #   - min, max and average response times
  defp update_stats(%Result{min: min, max: max} = result, duration) do
    result =
      if duration < min do
        Map.put(result, :min, duration)
      else
        result
      end

    if duration > max do
      Map.put(result, :max, duration)
    else
      result
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
