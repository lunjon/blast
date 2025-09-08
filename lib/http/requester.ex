defmodule Blast.Requester do
  @moduledoc false

  @callback send(Blast.Request.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, any()}
end
