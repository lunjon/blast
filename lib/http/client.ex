defmodule Blast.HttpClient do
  @moduledoc false
  alias Blast.Request, as: Req

  def send(req) do
    %Req{
      method: m,
      url: u,
      headers: h,
      body: b
    } = req

    {body, headers} = get_body(b, h)

    request = %HTTPoison.Request{
      method: m,
      url: u,
      headers: headers,
      body: body,
      options: [
        # This is for establishing the TCP (incl. TLS) connection.
        timeout: 10_000,
        # The timeout for receiving the HTTP response.
        recv_timeout: 10_000
      ]
    }

    HTTPoison.request(request)
  end

  defp get_body(body, headers) when is_binary(body) do
    {body, headers}
  end

  defp get_body(body, headers) when is_list(body) or is_map(body) do
    body = JSON.encode!(body)
    {body, Map.put_new(headers, "Content-Type", "application/json")}
  end
end
