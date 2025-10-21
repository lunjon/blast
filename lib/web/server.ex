defmodule Blast.Server do
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

  EEx.function_from_file(:defp, :render_data, "lib/web/data.heex", [:responses, :errors])

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/start" do
    {status, error} =
      case Orchestrator.start() do
        :ok -> {200, nil}
        {:error, err} -> {500, "Error starting blast - #{err}"}
      end

    json_resp(conn, %{error: error}, status)
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
    content = render_data(state.endpoints, state.errors)
    send_resp(conn, 200, content)
  end

  get "/status" do
    running =
      case Orchestrator.get_status() do
        :idle -> false
        :running -> true
      end

    json_resp(conn, %{running: running})
  end

  # Static files.
  # 
  # These could be served with caching, but since this
  # is running locally we do not need to consider efficiency
  # that much.
  #
  # The static files are marked as external resources
  # meaning that changes to them forces recompilation.
  # This is useful when developing since the content
  # is embedded in the code.

  @static_root "lib/web/static"
  static_files = Path.wildcard("lib/web/static/*")

  for path <- static_files do
    @external_resource path
  end

  @favicon File.read!("#{@static_root}/favicon.ico")
  get("/static/favicon.ico") do
    conn
    |> put_resp_header("content-type", "image/x-icon")
    |> put_resp_header("cache-control", "private; max-age: 3600")
    |> send_resp(200, @favicon)
  end

  @css File.read!("#{@static_root}/style.css")
  get("/static/style.css") do
    send_resp(conn, 200, @css)
  end

  @js File.read!("#{@static_root}/index.js")
  get("/static/index.js") do
    conn
    |> put_resp_header("content-type", "text/javascript")
    |> send_resp(200, @js)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp json_resp(conn, body, status \\ 200) do
    content = JSON.encode!(body)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, content)
  end

  defp render_status(status, count) when is_integer(status) do
    cond do
      status >= 500 ->  "<span style=\"font-weight: bold; color: var(--reder)\">#{status}</span> (#{count})"
      status >= 400 ->  "<span style=\"font-weight: bold; color: var(--yellower)\">#{status}</span> (#{count})"
      status >= 200 ->  "<span style=\"font-weight: bold; color: var(--greener)\">#{status}</span> (#{count})"
      true -> "<span>#{status} (#{count})</span>"
    end
  end
end
