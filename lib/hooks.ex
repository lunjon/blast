defmodule Blast.Hooks do
  alias Blast.Hooks
  alias Blast.Request

  @typedoc """
  A `context` is a map created ...
  """
  @type context :: map()

  @type init_func :: (-> {:ok, context} | {:error, binary})
  @type on_start_func :: (context -> context)
  @type on_request_func :: (context, Request.t -> context)
  
  @type t :: %{
    cx: context(),
    on_start: on_start_func(),
    on_request: on_request_func(),
  }

  defstruct cx: %{},
            on_start: nil,
            on_request: nil

  @doc """
  Loads hooks from an Elixir file.
  """
  @spec load_hooks(binary()) :: Hooks.t()
  def load_hooks(filepath) do
    [{module, _}] = Code.require_file(filepath, ".")

    hooks =
      if Kernel.function_exported?(module, :init, 0) do
        cx = apply(module, :init, []) |> get_context()
        %Hooks{cx: cx}
      else
        %Hooks{cx: %{}}
      end

    hooks =
      if Kernel.function_exported?(module, :on_request, 2) do
        Map.put(hooks, :on_request, fn cx, req ->
          apply(module, :on_request, [cx, req])
        end)
      else
        hooks
      end

    hooks =
      if Kernel.function_exported?(module, :on_start, 1) do
        Map.put(hooks, :on_start, fn cx ->
          apply(module, :on_start, [cx])
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
  Calls the on_start hook (if any) and updates the context.
  """
  def on_start(%Hooks{cx: cx} = hooks) do
    case hooks.on_start do
      nil -> hooks
      func ->
        cx = func.(cx) |> handle_on_start(cx)
        update_context(hooks, cx)
    end
  end

  @doc """
  Calls the on_request hook.
  """
  def on_request(%Hooks{cx: cx} = hooks, %Request{} = req) do
    case hooks.on_request do
      nil -> 
        {hooks, req}
      func ->
        {cx, req} = func.(cx, req)
        {update_context(hooks, cx), req}
    end
  end

  # Handles the result from the on_start hook.
  defp handle_on_start({:ok, cx}, _old), do: cx
  defp handle_on_start(:ok, cx), do: cx

  defp update_context(hooks, cx) do
    Map.put(hooks, :cx, cx)
  end
end
