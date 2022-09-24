defmodule Core.Management.Handler do
  require Logger
  alias Core.Manager

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
    |> handle_receive(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp handle_receive({:ok, line}, socket) do
    Logger.info("Received message: #{line}")

    line
    |> String.split()
    |> process_request()
    |> send_response(socket)
  end

  defp handle_receive({:error, reason}, _socket) do
    Logger.info("Client disconnected: #{reason}")
  end

  defp send_response(msg, socket) do
    :gen_tcp.send(socket, msg <> "\n")
    serve(socket)
  end

  defp process_request(["status"]) do
    Manager.get_status()
    |> to_string()
    |> String.upcase()
  end

  defp process_request(["stop"]) do
    Manager.stop_all()
    "OK"
  end

  defp process_request(_) do
    "Unknown request"
  end
end
