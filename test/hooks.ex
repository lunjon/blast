defmodule Hooks do
  # NOTE! This is used by the tests.

  def init() do
    {:ok, %{init: true}}
  end

  def on_start(cx) do
    cx = Map.put(cx, :on_start, true)
    {:ok, cx}
  end

  def on_request(cx, req) do
    cx = Map.put(cx, :on_request, true)
    {cx, req}
  end
end
