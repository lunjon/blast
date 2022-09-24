defmodule Core.Management.Handler do
  @moduledoc """
  Handles a client that connects to the management API.
  """

  @doc """
  Handles a client connected on `socket`.
  Reads one line at a time.
  """
  def serve(socket) do
    socket
    |> read_line()
    |> write_response(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, line} = :gen_tcp.recv(socket, 0)
    line
  end

  defp write_response(line, socket) do
    # Echo request back as response
    :gen_tcp.send(socket, line)
  end
end
