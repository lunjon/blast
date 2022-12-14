defmodule Cli.ParserTest do
  use ExUnit.Case
  alias Blast.CLI.Parser

  @url "http://localhost"
  @urls "https://localhost/path"
  @urlq "https://localhost/path?query=true"

  @valid_filepath "mix.exs"

  describe "common errors" do
    test "no args" do
      {:error, _} = Parser.parse_args([])
    end

    test "missing url" do
      {:error, _} = Parser.parse_args(["--method", "GET"])
    end

    test "invalid method" do
      {:error, _msg} = Parser.parse_args(["--url", @url, "--method", "no"])
    end

    test "invalid mode" do
      {:error, _msg} = Parser.parse_args(["--url", @url, "--mode", "no"])
    end

    test "worker mode, missing --manager-address" do
      {:error, _msg} = Parser.parse_args(["--url", @url, "--mode", "worker"])
    end
  end

  describe "URLs" do
    test "valid" do
      urls = [
        @url,
        @urls,
        @urlq,
        "https://elixir-lang.org/path"
      ]

      for url <- urls do
        {:ok, _} = Parser.parse_args(["--url", url])
      end
    end

    test "invalid" do
      urls = [
        "",
        "/path",
        "htp:/lol",
        ":8080/path",
        "tls://invalid-scheme"
      ]

      for url <- urls do
        {:error, _} = Parser.parse_args(["--url", url])
      end
    end
  end

  describe "defaults" do
    test "no args" do
      {:error, _} = Parser.parse_args([])
    end

    test "help" do
      {:help, _msg} = Parser.parse_args(["--help"])
      {:help, _msg} = Parser.parse_args(["-h"])
    end

    test "values" do
      {:ok, args} = Parser.parse_args(["--url", @url])
      assert(args.url == @url)
      assert(args.method == "GET")
      assert(args.workers == 1)
      assert(args.duration == 10_000)
      assert(args.frequency == 0)
      assert not args.verbose
    end

    test "verbose" do
      {:ok, args} = Parser.parse_args(["--url", @url, "--verbose"])
      assert(args.verbose)
    end

    test "frequency" do
      {:ok, args} = Parser.parse_args(["--url", @url, "--frequency", "10"])
      assert(args.frequency == 10)
      {:ok, args} = Parser.parse_args(["--url", @url, "-f", "10"])
      assert(args.frequency == 10)
    end
  end

  describe "header parsing" do
    test "valid header" do
      {:ok, "name", "value"} = Parser.parse_keyvalue("name: value")
    end

    test "invalid headers" do
      {:error, _msg} = Parser.parse_keyvalue("")
      {:error, _msg} = Parser.parse_keyvalue("name:")
      {:error, _msg} = Parser.parse_keyvalue("name")
    end
  end

  describe "header option" do
    test "missing value" do
      {:error, _} = Parser.parse_args(["--url", @url, "--header"])
    end

    test "invalid value" do
      {:error, _} = Parser.parse_args(["--url", @url, "--header", "no"])
    end

    test "single header" do
      {:ok, args} = Parser.parse_args(["--url", @url, "--header", "name: value"])
      assert(Map.get(args.headers, "name") == "value")
    end

    test "short form" do
      {:ok, args} = Parser.parse_args(["--url", @url, "-H", "name: value"])
      assert(Map.get(args.headers, "name") == "value")
    end

    test "multiple unique headers" do
      {:ok, args} =
        Parser.parse_args(["--url", @url, "--header", "name: value", "-H", "other: different"])

      assert(Map.get(args.headers, "name") == "value")
      assert(Map.get(args.headers, "other") == "different")
    end

    test "multiple occurence of same header" do
      {:ok, args} = Parser.parse_args(["--url", @url, "-H", "name: v1", "-H", "name: v2"])
      assert(Map.get(args.headers, "name") == "v1; v2")
    end
  end

  describe "data options" do
    test "--data string" do
      {:ok, args} = Parser.parse_args(["--url", @url, "--data", "string"])
      assert(args.body == "string")
    end

    test "--data-form" do
      {:ok, args} =
        Parser.parse_args([
          "--url",
          @url,
          "--data-form",
          "key: value",
          "--data-form",
          "other: yes"
        ])

      {:form, _} = args.body
    end

    test "--data-file" do
      {:ok, args} = Parser.parse_args(["--url", @url, "--data-file", @valid_filepath])
      {:file, _} = args.body
    end

    test "--data & --data-form" do
      {:error, _} =
        Parser.parse_args(["--url", @url, "--data", @valid_filepath, "--data-form", "key: value"])
    end

    test "--data & --data-file" do
      {:error, _} =
        Parser.parse_args(["--url", @url, "--data", "string", "--data-file", @valid_filepath])
    end

    test "--data-form & --data-file" do
      {:error, _} =
        Parser.parse_args([
          "--url",
          @url,
          "--data-file",
          @valid_filepath,
          "--data-form",
          "key: value"
        ])
    end

    test "--data & --data-form & --data-file" do
      {:error, _} =
        Parser.parse_args([
          "--url",
          @url,
          "--data",
          "string",
          "--data-file",
          @valid_filepath,
          "--data-form",
          "key: value"
        ])
    end
  end

  describe "mode options" do
    test "default" do
      {:ok, args} = Parser.parse_args(["-u", @url])
      {:standalone, nil} = args.mode
    end

    test "manager mode" do
      {:ok, args} = Parser.parse_args(["-u", @url, "--mode", "manager"])
      {:manager, nil} = args.mode
    end

    test "worker mode" do
      {:ok, args} =
        Parser.parse_args(["-u", @url, "--mode", "worker", "--manager-address", "man"])

      {:worker, "man"} = args.mode
    end
  end
end
