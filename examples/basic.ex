defmodule Blast do
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
end
