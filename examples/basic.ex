defmodule Blast do
  def base_url() do
    "http://localhost:8080"
  end

  def requests() do
    [
      %{
        method: "get",
        path: "/testing"
      }
    ]
  end
end
