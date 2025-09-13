defmodule Blast do
  use Blastfile

  def base_url() do
    "http://localhost:8080"
  end

  def requests() do
    [
      %{
        method: "get",
        path: "/testing",
        # Make this request more likely to be sent
        weight: 5
      },
      %{
        method: "post",
        path: "/resource"
      }
    ]
  end

  def pre_request(context, req) do
    req = put_header(req, "Authorization", "name")
    {context, req}
  end
end
