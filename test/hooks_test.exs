defmodule Blast.Hooks.Test do
  use ExUnit.Case
  alias Blast.{Hooks, Request}

  test("valid hooks file") do
    {:ok, hooks} = Hooks.load_hooks("test/hooks.ex")
    assert hooks.cx
    assert hooks.on_start
    assert hooks.on_request

    {:ok, cx} = hooks.on_start.(hooks.cx)
    assert is_map(cx)
    assert cx.on_start == true

    {cx, _req} = hooks.on_request.(cx, %Request{method: "GET", url: "http://localhost", headers: []})
    assert is_map(cx)
    assert cx.on_request == true
  end
end
