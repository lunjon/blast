defmodule Blastfile do
  @moduledoc """
  A module for implementing the Blastfile
  """
  alias Blast.Request

  @doc """
  Returns the base URL to use for the requests.
  Thus all requests need only to specify the URL path.
  """
  @callback base_url() :: String.t()

  @doc """
  Returns the list of requests to send.
  """
  @callback requests() :: [Request.t()]

  @doc """
  Optional function to initialize the _context_,
  i.e. the state passed to the `start` hook and,
  in turn, the other hooks.
  """
  @callback init() :: {:ok, any()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Blastfile

      alias Blast.Request

      def put_header(req, name, value) do
        Request.put_header(req, name, value)
      end

      # Inject default implementations.

      def init() do
        {:ok, %{}}
      end

      def start(state) do
        {:ok, state}
      end

      def pre_request(context, req) do
        {context, req}
      end

      defoverridable init: 0
      defoverridable start: 1
      defoverridable pre_request: 2
    end
  end
end
