defmodule BlastTest.TestServer do
  use Plug.Router

  @moduledoc """
  This is used as a target in the integration tests.
  """

  plug(:match)
  plug(:dispatch)

  get "/ok" do
    send_resp(conn, 200, "OK")
  end

  get "/not-found" do
    send_resp(conn, 404, "Not Found")
  end
end
