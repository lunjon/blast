defmodule BlastTest.ConfigStore do
  use ExUnit.Case, async: true
  alias Blast.ConfigStore

  describe("put should") do
    test("add value") do
      :ok = ConfigStore.put(:what, "ever")
    end
  end
end
