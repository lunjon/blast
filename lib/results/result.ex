defmodule Blast.Result do
  @type t :: %{responses: map()}
  defstruct responses: %{}

  def update(%Blast.Result{responses: res} = result, response) do
    res = Map.update(res, response.request_url, 0, fn count -> count + 1 end)
    Map.replace(result, :responses, res)
  end
end
