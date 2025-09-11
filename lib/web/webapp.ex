defmodule Blast.WebApp do
  use Plug.Router
  require EEx
  alias Blast.Orchestrator

  @moduledoc false

  EEx.function_from_file(:defp, :render_index, "lib/web/index.heex", [:status])
  EEx.function_from_file(:defp, :render_data, "lib/web/data.heex", [:responses])

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    status = Orchestrator.get_status() |> to_string() |> String.capitalize()
    content = render_index(status)
    send_resp(conn, 200, content)
  end

  get "/data" do
    data = get_data() |> IO.inspect()
    content = render_data(data)
    send_resp(conn, 200, content)
  end

  defp get_data() do
    # result = Orchestrator.get_stats()

    # result.responses
    # |> Enum.map(fn {url, _status_counts} ->
    #   url
    # end)

    %{}
  end
end
