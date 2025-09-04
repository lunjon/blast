defmodule Blast.Main do
  alias Blast.CLI

  @moduledoc """
  This is only used as the escript main module.
  """

  def main(args) do
    CLI.main(args)
    Process.sleep(:infinity)
  end
end
