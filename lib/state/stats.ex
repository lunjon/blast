defmodule Blast.Stats do
  @moduledoc """
  This module contains statistics for a current running blast.
  """

  alias Blast.EndpointStats
  alias HTTPoison.Response

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
    |> IO.inspect()
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
          nil -> %EndpointStats{average: duration, min: duration, max: duration}
          st -> EndpointStats.update(st, duration)
        end
      end
    )
  end
end
