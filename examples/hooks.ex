defmodule Blast do
  use Blastfile

  def base_url() do
    "http://localhost:1234"
  end

  def requests() do
    [
      %{
        method: "post",
        path: "/internal/tests",
        body: "{\"test\": true}",
        headers: [
          {"content-type", "application/json"}
        ]
      }
    ]
  end

  def init() do
    context = %{token: get_token(), timestamp: Time.utc_now()}
    {:ok, context}
  end

  # This is by a worker before each request is sent.
  def pre_request(cx, req) do
    cx = update_context(cx)
    req = put_header(req, "Authorization", "Bearer #{cx.token}")
    {cx, req}
  end

  # We can have private functions that are called from the hooks.
  defp update_context(%{token: token, timestamp: ts} = cx) do
    now = Time.utc_now()

    if Time.diff(now, ts, :second) > 200 do
      token = get_token()
      %{token: token, timestamp: now}
    else
      cx
    end
  end

  defp get_token() do
    # Something to get an authentication token ...
    "..."
    |> String.trim(token)
  end
end
