defmodule Blast.WebApp do
  use Plug.Router
  require EEx

  # This module 
  @moduledoc false

  EEx.function_from_file(:defp, :render_index, "lib/web/index.heex", [:status])
  EEx.function_from_file(:defp, :render_data, "lib/web/data.heex", [:responses])

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    content = render_index("OK") |> IO.inspect()
    send_resp(conn, 200, content)
  end

  get "/data" do
    data = get_data() |> IO.inspect()
    content = render_data(data)
    send_resp(conn, 200, content)
  end

  defp get_data() do
    alias Blast.Collector

    result = Collector.get()

    result.responses
    |> Enum.map(fn {url, _status_counts} ->
      url
    end)
  end
end
