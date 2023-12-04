# README
# ======
# This is used to test external hooks.

defmodule Blast.Hools do
  def pre_request(req) do
    token = "test"
    bearer = "Bearer #{token}"
    req
    |> Core.Request.put_header("Authorization", bearer)
  end
end

