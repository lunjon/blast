defmodule Blast.TUI do
  @moduledoc """
  This module is responsible for rendering the current state
  of the application. The interface is currently very limited
  and does not support user input of any kind.

  TODO:
    - show average response time
    - stats per route: min, max and average response time
  """

  use GenServer, restart: :transient
  require Logger
  alias IO.ANSI
  alias Blast.{Collector, Result}

  @period 1000

  @type state :: %{
          # Last time rendered
          prev_time: integer(),
          # Previous amount of requests sent
          prev_count: integer()
        }

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    Process.send_after(self(), :run, @period)
    state = %{prev_time: System.monotonic_time(:millisecond), prev_count: 0}
    {:ok, state}
  end

  def handle_info(:run, state) do
    result = Collector.get()
    {state, reqs_per_sec} = get_request_count(state, result)

    render(result, reqs_per_sec)

    Process.send_after(self(), :run, @period)
    {:noreply, state}
  end

  @spec get_request_count(state(), Result.t()) :: {state(), integer()}
  defp get_request_count(%{prev_time: ts, prev_count: count} = state, res) do
    curr = System.monotonic_time(:millisecond)
    diff = (curr - ts) / 1000

    requests_per_sec = ((res.count - count) / diff) |> ceil()

    state =
      state
      |> Map.put(:prev_time, curr)
      |> Map.put(:prev_count, res.count)

    {state, requests_per_sec}
  end

  defp render(result, reqs_per_sec) do
    clear_screen([])
    |> move(0, 0)
    |> flush()

    write_format([:green_background, :black, "             Stats             "])
   
    move([], 3, 0)
    |> add_line("Number of requests sent:   #{result.count}")
    |> add_line("Number of requests/second: #{reqs_per_sec}")
    |> add_line()
    |> add_line("Average response time:     #{Float.round(result.average, 1)} ms")
    |> add_line("Minimum response time:     #{result.min} ms")
    |> add_line("Maximum response time:     #{result.max} ms")
    |> add_line()
    |> flush()

    write_format([:green_background, :black, "           Endpoints           "])

    move([], 12, 0)
    |> render_result(result.responses)
    |> flush()
  end

  defp flush(ops) do
    Enum.join(ops) |> IO.puts()
    []
  end

  defp move(ops, line, col) do
    ops ++ [ANSI.cursor(line, col)]
  end

  defp clear_screen(ops) do
    ops ++ [ANSI.clear()]
  end

  defp write_format(kw) do
    ANSI.format(kw) |> IO.puts()
  end

  defp add_line(ops, line \\ ""), do: add_lines(ops, [line])

  defp add_lines(ops, lines) do
    lines =
      Enum.map(lines, fn line ->
        String.trim_trailing(line) <> "\n"
      end)

    ops ++ lines
  end

  defp render_result(ops, responses) do
    lines =
      responses
      |> Enum.map(fn {endpoint, statuses} ->
        [endpoint] ++
          Enum.map(statuses, fn {status, count} ->
            status =
              cond do
                status < 200 -> status
                status >= 300 and status < 400 -> yellow(status)
                200 <= status and status < 300 -> green(status)
                400 <= status and status < 500 -> yellow(status)
                true -> red(status)
              end

            "    #{status}: #{count}"
          end)
      end)
      |> List.flatten()

    add_lines(ops, lines)
  end

  def error(err) do
    IO.puts(:stderr, "#{red("error")}: #{err}")
  end

  def yellow(text) do
    style([ANSI.yellow()], text)
  end

  def green(text) do
    style([ANSI.green()], text)
  end

  def green_italic(text) do
    style([ANSI.italic(), ANSI.green()], text)
  end

  def red(text) do
    style([ANSI.red()], text)
  end

  def italic(text) do
    style([ANSI.italic()], text)
  end

  defp style(styles, text) do
    [
      Enum.join(styles),
      to_string(text),
      ANSI.reset()
    ]
    |> Enum.join()
  end
end
