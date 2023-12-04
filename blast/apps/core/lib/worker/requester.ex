defmodule Core.Requester do
  @moduledoc """
  Behaviour for sending requests.
  """

  @callback send(Core.Request.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, any()}
end

defmodule Core.RequesterImpl do
  @moduledoc """
  The default implementation of Core.Requester behaviour
  for sending HTTP requests.
  """
  @behaviour Core.Requester

  alias Core.Request, as: Req

  @impl Core.Requester
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
