defmodule Blast.Controller do
  @moduledoc """
  A Controller is used to define how workers are started
  when running the load tests.

  An implementation is derived from this be implementating
  the Blast.Controller behaviour.

  ## Usage
  First you must use this: `use Blast.Controller`

  Then you have to implement the Blast.Controller callbacks.

  ## Implementations
  Todo:
  - square
  - triangle
  - sawtooth
  """

  @doc """
  Start the controller.

  The first argument is the arguments passed to the `start_link` function.
  It is expected to use that to create the state (a map) and return it
  in an `{:ok, map()}` tuple.

  If anything goes wrong it can return `{:error, any()}`.
  """
  @callback start(any()) :: {:ok, map()} | {:error, any()}

  @doc """
  This is called when stopping all workers.
  The stopping of workers is handled already so this only
  have to update the state.
  """
  @callback stop(map()) :: map()

  @doc """
  This callback is used for any message that is sent to the server.
  """
  @callback handle_message(any(), map()) :: {:ok, map()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger
      alias Blast.{Config, WorkerSupervisor}

      @behaviour Blast.Controller
      @me Controller

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: @me)
      end

      @impl GenServer
      def init(args) do
        case args do
          nil -> {:ok, %{status: :idle, config: nil}}
          args ->
            {:ok, state} = start(args)
            {:ok, Map.put(state, :status, :running)}
        end
      end

      @impl GenServer
      def handle_call(:stop, _from, %{status: status} = state) do
        state =
          case status do
          :idle -> state
          :running ->
            WorkerSupervisor.stop_workers()
            stop(state) |> Map.put(:status, :idle)
        end

        {:reply, :ok, state}
      end

      @impl GenServer
      def handle_info(msg, state) do
        state =
          case handle_message(msg, state) do
            {:ok, new_state} -> new_state
            {:error, err} ->
              Logger.error("Error handling message: #{err}")
              state
          end

      	{:noreply, state}
      end

      # Use this to send a message to self with a delay.
      # The message will be passed to `handle_message`.
      #
      # NOTE! This is only safe to use internally in the server.
      defp send_self(msg, delay_ms) do
        Process.send_after(self(), msg, delay_ms)
      end
    end
  end

  # TODO: define default methods using something like (see __before_compile__):
  # https://elixirforum.com/t/macro-check-is-there-a-specific-function-inside-a-module/56861
end
