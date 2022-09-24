defmodule Pyro.Main do
  require Logger

  @help """
    quit      Exit.
    help      Show help this message.
    status    Get current status of server.
  """

  def main(_args) do
    opts = [:binary, :inet, active: false, packet: :line]

    case :gen_tcp.connect({127, 0, 0, 1}, 4444, opts) do
      {:ok, client} ->
        loop(client)

      {:error, reason} ->
        IO.puts(:stderr, "ERROR: #{reason}")
    end
  end

  defp loop(socket) do
    IO.write("> ")

    IO.read(:line)
    |> String.trim()
    |> String.split()
    |> process(socket)

    loop(socket)
  end

  defp process(["quit"], socket) do
    IO.puts("Bye!")
    :gen_tcp.close(socket)
    System.stop(0)
  end

  defp process(["help"], _socket) do
    IO.puts(@help)
  end

  defp process(["status"], socket) do
    send_and_receive(socket, "status")
  end

  defp process(["stop"], socket) do
    send_and_receive(socket, "stop")
  end

  defp process(words, _socket) do
    line = Enum.join(words, " ")
    IO.puts("invalid command: #{line}")
    IO.puts("Use 'help' or '?' to get help")
  end

  defp send_and_receive(socket, msg) do
    # Add newline
    msg = "#{msg}\n"

    with :ok <- :gen_tcp.send(socket, msg),
         {:ok, response} <- :gen_tcp.recv(socket, 0, 5000) do
      IO.puts(response)
    else
      {:error, err} -> IO.puts("ERROR: #{err}")
    end
  end
end
