defmodule Blast.WebApp do
  use Plug.Router
  require EEx
  alias Blast.ConfigStore
  alias Blast.Orchestrator

  @moduledoc false

  # TODO: https://hexdocs.pm/plug/Plug.Router.html#module-error-handling

  EEx.function_from_file(:defp, :render_index, "lib/web/index.heex", [
    :base_url,
    :frequency,
    :workers
  ])

  EEx.function_from_file(:defp, :render_data, "lib/web/data.heex", [:responses])

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/start" do
    {status, content} =
      case Orchestrator.start() do
        :ok -> {200, ""}
        {:error, err} -> {500, "Error starting blast - #{err}"}
      end

    send_resp(conn, status, content)
  end

  get "/stop" do
    Orchestrator.stop()
    send_resp(conn, 200, "")
  end

  get "/" do
    config = ConfigStore.get()

    content = render_index(config.base_url, config.frequency, config.workers)
    send_resp(conn, 200, content)
  end

  get "/data" do
    state = Orchestrator.get_state()
    # endpoints = state.endpoints
    #   |> Enum.map(fn {url, _} -> url end)
    content = render_data(state.endpoints)
    send_resp(conn, 200, content)
  end

  get "/status" do
    running =
      case Orchestrator.get_status() do
        :idle -> false
        :running -> true
      end

    content = JSON.encode!(%{running: running})
    send_resp(conn, 200, content)
  end
end
