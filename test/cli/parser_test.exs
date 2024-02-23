defmodule Cli.ParserTest do
  use ExUnit.Case
  alias Blast.CLI.Parser

  defp get_args(args \\ []) do
    ["--specfile", "test/cli/blast.yml"] ++ args
    |> Enum.uniq()
  end

  describe "defaults" do
    test "help" do
      {:help, _msg} = Parser.parse_args(["--help"])
      {:help, _msg} = Parser.parse_args(["-h"])
    end

    test "values" do
      args = get_args()
      {:ok, args} = Parser.parse_args(args)
      assert(args.workers == 1)
      assert(args.frequency == 1)
      assert not args.verbose
    end

    test "verbose" do
      args = get_args(["--verbose"])
      {:ok, args} = Parser.parse_args(args)
      assert(args.verbose)
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

  describe "--hooks <module> should" do
    test "accept arg given valid file" do
      args = get_args([ "--hooks", "mix.exs" ])
      {:ok, _} = Parser.parse_args(args)
    end

    test "return error given unknown file" do
      {:error, _} =
        get_args([
          "--hooks",
          "non-existing-file.txt"
        ])
        |>Parser.parse_args()
    end
  end

end
