defmodule Blast.CLI.Output do
  alias Blast.Result
  alias IO.ANSI

  @spec result(Result.t()) :: String.t()
  def result(result) do
    Enum.each(result.responses, fn {url, statuses} ->
      IO.puts(url)

      Enum.each(statuses, fn {status, count} ->
        IO.puts("    #{status}: #{count}")
      end)
    end)
  end

  def error(err) do
    IO.puts(:stderr, "#{red("error")}: #{err}")
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
      text,
      ANSI.reset()
    ]
    |> Enum.join()
  end
end
