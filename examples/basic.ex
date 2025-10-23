defmodule Blast do
  use Blastfile

  def base_url() do
    "http://localhost:13001"
  end

  def requests() do
    [
      %{method: "get", path: "/fine"},
      %{method: "get", path: "/~/status/random"},
      # %{method: "get", path: "/~/status/500"},
      %{method: "get", path: "/~/timeout"}
    ]
  end
end
