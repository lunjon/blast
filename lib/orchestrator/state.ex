defmodule Blast.State do
  @moduledoc """
  This module contains statistics for a current running blast.
  """

  alias Blast.EndpointStats
  alias HTTPoison.{Response}
  alias Blast.Request

  @type status() :: :idle | :running

  @type t :: %__MODULE__{
          status: status(),
          # Total request count.
          total: integer(),
          status_counts: %{integer() => integer()},
          endpoints: %{String.t() => EndpointStats.t()},
          errors: %{String.t() => MapSet.t()}
        }

  defstruct status: :idle,
            total: 0,
            status_counts: %{},
            endpoints: %{},
            errors: %{}

  def set_status(state, status) when is_struct(state) do
    put_in(state, [Access.key!(:status)], status)
  end

  @spec add_response(t(), Response.t(), integer()) :: t()
  def add_response(state, %Response{} = res, duration) do
    %Response{
      request: request,
      request_url: url,
      status_code: status_code
    } = res

    endpoint = get_endpoint(request.method, url)

    Map.update(state, :total, 1, &(&1 + 1))
    |> update_status_counts(status_code)
    |> update_endpoint(endpoint, duration, status_code)
  end

  @spec get_endpoint(atom() | binary(), binary()) :: binary()
  def get_endpoint(method, url) do
    m =
      cond do
        is_binary(method) -> method
        is_atom(method) -> to_string(method)
        true -> inspect(method)
      end

    %URI{path: path} = URI.parse(url)
    "#{String.upcase(m)} #{path}"
  end

  @spec add_error(t(), Request.t(), binary()) :: t()
  def add_error(state, request, error) do
    endpoint = get_endpoint(request.method, request.url)

    update_in(
      state,
      [Access.key!(:errors), endpoint],
      fn value ->
        case value do
          nil -> MapSet.new([error])
          set -> MapSet.put(set, error)
        end
      end
    )
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

  defp update_endpoint(stats, endpoint, duration, status_code) do
    update_in(
      stats,
      [Access.key!(:endpoints), endpoint],
      fn
        nil -> %EndpointStats{min: duration, max: duration}
        ep -> EndpointStats.update(ep, duration, status_code)
      end
    )
  end
end
