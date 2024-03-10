defmodule Blast.Requester do
  @moduledoc """
  Behaviour for sending requests.
  """

  @callback send(Blast.Request.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, any()}
end

defmodule Blast.HttpRequester do
  @moduledoc """
  The default implementation of Blast.Requester behaviour
  for sending HTTP requests.
  """
  @behaviour Blast.Requester

  alias Blast.Request, as: Req

  @impl Blast.Requester
  def send(%Req{} = req) do
    %Req{
      method: m,
      url: u,
      headers: h,
      body: b
    } = req

    request = %HTTPoison.Request{
      method: m,
      url: u,
      headers: h,
      body: b
    }

    HTTPoison.request(request)
  end
end
