defmodule Cli.ParserTest do
  use ExUnit.Case
  alias Blast.CLI.Parser

  describe "defaults" do
    test "help" do
      {:help, _msg} = Parser.parse_args(["--help"])
      {:help, _msg} = Parser.parse_args(["-h"])
    end

    test "values" do
      args = get_args()
      {:ok, args} = Parser.parse_args(args)
      assert(args.workers == 2)
      assert(args.frequency == 10)
    end

    test "frequency" do
      args = get_args(["--frequency", "10"])
      {:ok, args} = Parser.parse_args(args)
      assert(args.frequency == 10)
      args = get_args(["-f", "10"])
      {:ok, args} = Parser.parse_args(args)
      assert(args.frequency == 10)
    end
  end

  defp get_args(args \\ []) do
    (["--blastfile", "test/blast.ex"] ++ args)
    |> Enum.uniq()
  end
end
