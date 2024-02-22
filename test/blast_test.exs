defmodule BlastTest do
  use ExUnit.Case
  doctest Blast

  test "greets the world" do
    assert Blast.hello() == :world
  end
end
