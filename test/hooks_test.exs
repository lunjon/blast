defmodule BlastTest.Hooks do
  use ExUnit.Case
  alias Blast.{Hooks, Request}

  test("valid hooks") do
    {:ok, hooks} = Hooks.load(BlastTest.Hooks.Sample1)
    assert hooks.cx
    assert hooks.start
    assert hooks.pre_request

    {:ok, cx} = hooks.start.(hooks.cx)
    assert is_map(cx)
    assert cx.start == true

    {cx, _req} =
      hooks.pre_request.(cx, %Request{method: "GET", url: "http://localhost", headers: []})

    assert is_map(cx)
    assert cx.pre_request == true
  end
end

defmodule BlastTest.Hooks.Sample1 do
  def init() do
    {:ok, %{}}
  end

  def start(_context) do
    {:ok, %{start: true}}
  end

  def pre_request(context, req) do
    {Map.put(context, :pre_request, true), req}
  end
end
