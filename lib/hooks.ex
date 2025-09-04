defmodule Blast.Hooks do
  alias Blast.Hooks
  alias Blast.Request

  @typedoc """
  A `context` is a map created by the optional `init` function in the Blast module.
  It's an empty map by default.
  """
  @type context :: map()

  @type init_func :: (-> {:ok, context} | {:error, binary})
  @type start_func :: (context -> context)
  @type pre_request_func :: (context, Request.t() -> context)

  @type t :: %{
          cx: context(),
          init: init_func(),
          start: start_func(),
          pre_request: pre_request_func()
        }

  defstruct cx: %{},
            init: nil,
            start: nil,
            pre_request: nil

  @doc """
  Loads hooks from an Elixir file.
  """
  @spec load(module()) :: {:ok, Hooks.t()}
  def load(module) do
    # Check init func.
    hooks =
      if Kernel.function_exported?(module, :init, 0) do
        cx = apply(module, :init, []) |> get_context()
        %Hooks{cx: cx}
      else
        %Hooks{cx: %{}}
      end

    # Check pre_request func.
    hooks =
      if Kernel.function_exported?(module, :pre_request, 2) do
        Map.put(hooks, :pre_request, fn cx, req ->
          apply(module, :pre_request, [cx, req])
        end)
      else
        hooks
      end

    # Check start func.
    hooks =
      if Kernel.function_exported?(module, :start, 1) do
        Map.put(hooks, :start, fn cx ->
          apply(module, :start, [cx])
        end)
      else
        hooks
      end

    {:ok, hooks}
  end

  defp get_context(:ok), do: %{}
  defp get_context({:ok, cx}) when is_map(cx), do: cx
  defp get_context({:error, _} = err), do: err

  defp get_context(res) do
    {:error, "unrecognizable return from init: #{inspect(res)}"}
  end

  @doc """
  Calls the start hook (if any) and updates the context.
  """
  def start(%Hooks{cx: cx, start: func} = hooks) do
    case func do
      nil ->
        hooks

      func ->
        cx = func.(cx) |> handle_start(cx)
        update_context(hooks, cx)
    end
  end

  @doc """
  Calls the pre_request hook.
  """
  def pre_request(%Hooks{cx: cx, pre_request: func} = hooks, %Request{} = req) do
    case func do
      nil ->
        {hooks, req}

      func ->
        {cx, req} = func.(cx, req)
        {update_context(hooks, cx), req}
    end
  end

  # Handles the result from the start hook.
  defp handle_start({:ok, cx}, _old), do: cx
  defp handle_start(:ok, cx), do: cx

  defp update_context(hooks, cx) do
    Map.put(hooks, :cx, cx)
  end
end
