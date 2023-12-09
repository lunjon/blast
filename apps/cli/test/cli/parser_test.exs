defmodule Cli.ParserTest do
  use ExUnit.Case
  alias Blast.CLI.Parser

  describe "defaults" do
    test "no args" do
      {:ok, _} = Parser.parse_args([])
    end

    test "help" do
      {:help, _msg} = Parser.parse_args(["--help"])
      {:help, _msg} = Parser.parse_args(["-h"])
    end

    test "values" do
      {:ok, args} = Parser.parse_args([])
      assert(args.workers == 1)
      assert(args.frequency == 1)
      assert not args.verbose
    end

    test "verbose" do
      {:ok, args} = Parser.parse_args(["--verbose"])
      assert(args.verbose)
    end

    test "frequency" do
      {:ok, args} = Parser.parse_args(["--frequency", "10"])
      assert(args.frequency == 10)
      {:ok, args} = Parser.parse_args(["-f", "10"])
      assert(args.frequency == 10)
    end
  end

  describe "--hooks <module> should" do
    test "accept arg given valid file" do
      args = [
        "--hooks",
        "mix.exs"
      ]

      {:ok, _} = Parser.parse_args(args)
    end

    test "return error given unknown file" do
      args = [
        "--hooks",
        "non-existing-file.txt"
      ]

      {:error, _} = Parser.parse_args(args)
    end
  end
end
