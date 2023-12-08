defmodule Blast.CLI.Output do
  alias Core.Result
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
    ANSI.green() <> text <> ANSI.reset()
  end

  def red(text) do
    ANSI.red() <> text <> ANSI.reset()
  end
end
