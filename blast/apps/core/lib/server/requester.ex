defmodule Core.Requester do
  @moduledoc """
  Behaviour for sending requests.
  """

  @callback send(HTTPoison.Request.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
end

defmodule Core.RequesterImpl do
  @behaviour Core.Requester
  @impl Core.Requester
  def send(request) do
    HTTPoison.request(request)
  end
end
