# README
# ======
# This is used to test hooks.

defmodule Blast.Hools do
  def init() do
    :ok
  end

  def on_request(cx, req) do
    token = "test"
    bearer = "Bearer #{token}"

    req = Blast.Request.put_header(req, "Authorization", bearer)
    {cx, req}
  end
end

