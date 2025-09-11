defmodule Blast.Controller do
  @moduledoc """
  A Controller is used to define how workers are started
  when running the load tests. Workers are started using `WorkerSupervisor`.

  An implementation is derived from this be implementating
  the Blast.Controller behaviour.

  ## Usage
  First you must use this: `use Blast.Controller`
  Then you have to implement the Blast.Controller callbacks.
  """

  @doc """
  The first argument is the arguments passed to the `start_link` function.
  It is expected to use that to create the state (a map) and return it
  in an `{:ok, map()}` tuple.
  """
  @callback initialize(any()) :: {:ok, any()}

  @doc """
  Start the controller.

  If anything goes wrong it can return `{:error, any()}`.
  """
  @callback start(any()) :: {:ok, any()} | {:error, any()}

  @doc """
  This is called when stopping all workers.
  The stopping of workers is handled already so this only
  have to update the state.
  """
  @callback stop(any()) :: any()

  @doc """
  This callback is used for any message that is sent to the server.
  """
  @callback handle_message(any(), any()) :: any()

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

      @type state() :: %{
              status: :idle | :running,
              context: any()
            }

      @impl GenServer
      def init(args) do
        {:ok, cx} = initialize(args)
        {:ok, %{status: :idle, context: cx}}
      end

      @impl GenServer
      def handle_call(:start, _from, %{status: status, context: cx}) do
        # Only start if state is idle.
        {status, cx} =
          case status do
            :running ->
              {status, cx}

            :idle ->
              {:ok, cx} = start(cx)
              {:running, cx}
          end

        {:reply, :ok, %{status: status, context: cx}}
      end

      @impl GenServer
      def handle_call(:stop, _from, %{status: status, context: cx}) do
        {status, cx} =
          case status do
            :idle ->
              # Already stopped.
              {status, cx}

            :running ->
              WorkerSupervisor.stop_workers()
              {:idle, stop(cx)}
          end

        {:reply, :ok, %{status: status, context: cx}}
      end

      @impl GenServer
      def handle_info(msg, %{status: status, context: cx}) do
        cx = handle_message(msg, cx)
        {:noreply, %{status: status, context: cx}}
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
