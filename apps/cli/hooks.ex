# README
# ======
# This is used to test external hooks.

defmodule Blast.Hools do
  def init() do
    {:ok, %{test: true}}
  end

  def pre_request(cx, req) do
    IO.inspect(cx)
    token = "test"
    bearer = "Bearer #{token}"

    req = Blast.Request.put_header(req, "Authorization", bearer)
    {%{mutate: true}, req}
  end
end

