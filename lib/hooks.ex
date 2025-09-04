defmodule Blast.Hooks do
  alias Blast.Hooks
  alias Blast.Request

  @typedoc """
  A `context` can be created by the optional `init` function in the Blast module.
  It's an empty map by default.
  """
  @type context :: dynamic()

  @type init_func :: (-> {:ok, context()} | {:error, binary()})
  @type start_func :: (context -> context)
  @type pre_request_func :: (context, Request.t() -> {context(), Request.t()})

  @type t :: %{
          cx: context(),
          start: start_func(),
          pre_request: pre_request_func()
        }

  defstruct cx: %{},
            start: nil,
            pre_request: nil

  @doc """
  Try loading the optional hooks/callbacks for the blast (Elixir) module.

  If it exists, the `init()` function is invoked immediately and `cx` is set
  as the return value.
  """
  @spec load(module()) :: {:ok, Hooks.t()}
  def load(module) do
    cx =
      case Util.Mods.invoke(module, :init, 0) do
        {:ok, ret} -> get_context(ret)
        {:error, _} -> %{}
      end

    start =
      case function_exported?(module, :start, 1) do
        true -> fn cx -> apply(module, :start, [cx]) end
        _ -> nil
      end

    pre_request =
      case function_exported?(module, :pre_request, 2) do
        true -> fn cx, req -> apply(module, :pre_request, [cx, req]) end
        _ -> nil
      end

    hooks = %Hooks{cx: cx, start: start, pre_request: pre_request}
    {:ok, hooks}
  end

  defp get_context(:ok), do: %{}
  defp get_context({:ok, cx}), do: cx
  defp get_context({:error, _} = err), do: err

  defp get_context(res) do
    {:error, "unrecognizable return from init: #{inspect(res)}"}
  end

  @doc """
  Calls the start hook (if any) and updates the context.
  """
  def start(%Hooks{start: nil} = hooks), do: hooks

  def start(%Hooks{cx: cx, start: func} = hooks) do
    cx = func.(cx) |> handle_start(cx)
    update_context(hooks, cx)
  end

  @doc """
  Calls the pre_request hook if it exists
  """
  def pre_request(%Hooks{pre_request: nil} = hooks, req), do: {hooks, req}

  def pre_request(%Hooks{cx: cx, pre_request: func} = hooks, %Request{} = req) do
    {cx, req} = func.(cx, req)
    {update_context(hooks, cx), req}
  end

  # Handles the result from the start hook.
  defp handle_start({:ok, cx}, _old), do: cx
  defp handle_start(:ok, cx), do: cx

  defp update_context(hooks, cx) do
    Map.put(hooks, :cx, cx)
  end
end
