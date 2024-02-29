defmodule Blast.Result do
  alias HTTPoison.Response

  @moduledoc """
  Container for responses collected during a load test run.

  Responses are group per URL and status code. This means that
  each response has a URL which maps to a status count.
  """

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          responses: map()
        }

  defstruct count: 0,
            responses: %{}

  @spec add_response(t(), Response.t()) :: t()
  def add_response(result, %Response{} = res) do
    %Response{
      request: request,
      request_url: url,
      status_code: status
    } = res

    method = to_string(request.method) |> String.upcase()
    key = "#{method} #{url}"

    result
    |> update_in(
      [Access.key!(:responses), key],
      fn value -> update(value, status) end
    )
    |> update_in(
      [Access.key!(:count)],
      fn count -> count + 1 end
    )
  end

  defp update(nil, status) do
    %{status => 1}
  end

  defp update(statuses, status) do
    statuses
    |> Map.update(status, 1, &(&1 + 1))
  end
end
