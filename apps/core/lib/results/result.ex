defmodule Blast.Result do
  alias HTTPoison.Response

  @moduledoc """
  Container for responses collected during a load test run.

  The results are tracked based on the URL
  of the responses. The the `responses` map will
  contain something like:

      %{responses: %{"http://localhost" => %{200 => 97}}}

  This means there was 97 call to http://localhost that responded HTTP 200 (OK).
  """

  @type t :: %{responses: map()}

  defstruct responses: %{}

  @spec add_response(t(), Response.t()) :: t()
  def add_response(result, %Response{} = res) do
    %Response{
      request_url: url,
      status_code: status
    } = res

    result
    |> update_in(
      [Access.key!(:responses), url],
      fn value -> update(value, status) end
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
