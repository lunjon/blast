defmodule Requester.Mock do
  @behaviour Blast.Requester
  alias Blast.Request
  alias HTTPoison.Response

  @impl Blast.Requester
  def send(%Request{} = req) do
    Process.sleep(1)

    request = %HTTPoison.Request{
      method: req.method,
      url: req.url,
      headers: req.headers,
      body: req.body
    }

    res = %Response{
      status_code: 200,
      request_url: req.url,
      request: request
    }

    {:ok, res}
  end
end

defmodule Probe.Mock do
  @behaviour Blast.Probe

  @impl Blast.Probe
  def probe(_url), do: :ok
end

# Register the mocks.
Application.put_env(:blast, :requester, Requester.Mock)
Application.put_env(:blast, :probe, Probe.Mock)

require Logger
Logger.configure(level: :none)

ExUnit.start()
