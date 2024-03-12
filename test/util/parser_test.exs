defmodule Blast.Util.ParserTest do
  use ExUnit.Case
  alias Blast.Util.Parser

  setup_all(_context) do
    from = %{
      "any" => :a,
      "int" => 1,
      string: "sttrrr",
    }

    [from: from]
  end

  describe("[success] parse_map") do
    test("strict: true", %{from: from}) do
      # Arrange
      fields = [
        {"any", []},
        {"int", type: :int},
        {:string, into: :str, type: :string},
        {:test, default: "hest"},
      ]

      # Act & assert
      {:ok, result} = Parser.parse_map(from, fields, strict: true)
      assert result["any"] == :a
      assert result["int"] == 1
      assert result[:str] == "sttrrr"
      assert result[:test] == "hest"
    end

    test("strict: false", %{from: from}) do
      # Arrange
      fields = [
        {"any", []},
        {"integer", type: :int},
        {:string, into: :str, type: :string},
      ]

      # Act & assert
      {:ok, result} = Parser.parse_map(from, fields)
      assert result["any"] == :a
      assert result["integer"] == nil
    end
  end

  describe("[error] parse_map") do
    test("strict: true", %{from: from}) do
      # Arrange
      fields = [
        {"integer", type: :int},
      ]

      # Act & assert
      {:error, _reason} = Parser.parse_map(from, fields, strict: true)
    end

    test("invalid type", %{from: from}) do
      # Arrange
      fields = [
        {"any", type: :int},
        {:string, []},
      ]

      # Act & assert
      {:error, _reason} = Parser.parse_map(from, fields)
    end

    test("required", %{from: from}) do
      # Arrange
      fields = [
        {:missing, required: true},
      ]

      # Act & assert
      {:error, _reason} = Parser.parse_map(from, fields)
    end

    test("min") do
      # Arrange
      from = %{large: -1}
      fields = [
        {:large, min: 1},
      ]

      # Act & assert
      {:error, reason} = Parser.parse_map(from, fields)
      assert reason =~ "less than"
    end

    test("max") do
      # Arrange
      from = %{large: 1000}
      fields = [
        {:large, max: 10},
      ]

      # Act & assert
      {:error, reason} = Parser.parse_map(from, fields)
      assert reason =~ "greater than"
    end
  end
end
