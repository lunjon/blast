defmodule Blast.TcpProbe do
  @behaviour Blast.Probe

  @impl Blast.Probe
  def probe(url) do
    %URI{host: host, port: port} = URI.parse(url)

    host = String.to_charlist(host)

    case :gen_tcp.connect(host, port, []) do
      {:ok, socket} ->
        :gen_tcp.close(socket)

      {:error, reason} ->
        {:error, "failed to connect to #{host}:#{port}: #{inspect(reason)}"}
    end
  end
end
