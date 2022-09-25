defmodule Core.Result do
  alias HTTPoison.Response

  @moduledoc """
  Container for responses collected during a load test run.
  """

  @type t :: %{responses: map()}

  defstruct responses: %{}

  def add_response(result, %Response{request_url: url, status_code: status}) do
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
