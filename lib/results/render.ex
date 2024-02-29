defmodule Blast.Result.Render do
  @moduledoc """
  TODO: give better name.
  """

  use GenServer, restart: :transient
  alias IO.ANSI
  alias Blast.Bucket

  @period 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    Process.send_after(self(), :run, @period)
    {:ok, :state}
  end

  def handle_info(:run, state) do
    render()
    Process.send_after(self(), :run, @period)

    {:noreply, state}
  end

  defp render() do
    clear_screen([])
    |> move(0, 0)
    |> display()


    result = Bucket.get()
    IO.puts("Number of requests sent: #{result.count}\n")

    move([], 3, 0)
    |> display()

    result
    |> Map.get(:responses)
    |> render_result()
  end

  defp display(ops) do
    Enum.join(ops) |> IO.puts()
  end

  defp move(ops, line, col) do
    ops ++ [ANSI.cursor(line, col)]
  end

  defp clear_screen(ops) do
    ops ++ [ANSI.clear()]
  end

  @spec render_result(Result.t()) :: :ok
  def render_result(responses) do
    responses
    |> Enum.each(fn {endpoint, statuses} ->
      IO.puts(endpoint)

      Enum.each(statuses, fn {status, count} ->
        status =
          cond do
            status < 200 -> status
            status >= 300 and status < 400 -> yellow(status)
            200 <= status and status < 300 -> green(status)
            400 <= status and status < 500 -> yellow(status)
            true -> red(status)
          end

        IO.puts("    #{status}: #{count}")
      end)
    end)
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
