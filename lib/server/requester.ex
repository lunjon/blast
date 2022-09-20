defmodule Blast.Requester do
  @moduledoc """
  Behaviour for sending requests.
  """

  @callback send(HTTPoison.Request.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
end

defmodule Blast.RequesterImpl do
  @behaviour Blast.Requester
  @impl Blast.Requester
  def send(request) do
    HTTPoison.request(request)
  end
end
