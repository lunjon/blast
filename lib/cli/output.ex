defmodule Blast.CLI.Output do
  alias Blast.Result
  alias IO.ANSI

  @spec result(Result.t()) :: :ok
  def result(result) do
    result.responses
    |> Enum.each(fn {url, statuses} ->
      IO.puts(url)

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
