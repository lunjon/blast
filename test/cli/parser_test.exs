defmodule Cli.ParserTest do
  use ExUnit.Case
  alias Blast.CLI.ArgParser

  @url "http://localhost"

  test "no args" do
    {:error, _} = ArgParser.parse([])
  end

  test "help" do
    {:help, _msg} = ArgParser.parse(["--help"])
    {:help, _msg} = ArgParser.parse(["-h"])
  end

  test "minimal" do
    {:ok, args} = ArgParser.parse(["--url", @url])
    assert(args.url == @url)
  end

  test "verbose" do
    {:ok, args} = ArgParser.parse(["--url", @url, "--verbose"])
    assert(args.verbose)
  end
end
