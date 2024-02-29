defmodule Blast.Hooks.Test do
  use ExUnit
  alias Blast.{Hooks, Request}

  test("valid hooks file") do
    {:ok, hooks} = Hooks.load_hooks("test/hooks.ex")
    assert hooks.cx
    assert hooks.init
    assert hooks.on_start
    assert hooks.on_request

    cx = hooks.init.()
    assert is_map(cx)
    assert cx.init == true

    {:ok, cx} = hooks.on_start.(cx)
    assert is_map(cx)
    assert cx.on_start == true

    {cx, req} = hooks.on_request.(cx, %Request{})
    assert is_map(cx)
    assert cx.on_request == true
  end
end
