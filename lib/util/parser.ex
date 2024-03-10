defmodule Blast.Util.Parser do
  @moduledoc """
  TODO: write docs
  """

  @error_key :_parser_error

  @type field_type :: :string | :int | :map

  @type field :: {any(), keyword()}
  
  @doc """
  Parses a map into another map and uses the `fields`
  as a specification for the keys and values to extract.

  Each field is a two-element tuple: `{key, options}`, where
  `key` is the key used to get the value, and `options` is a keyword
  list contain options for the field.

  Allowed field options are:
  - `into: any()`: an alias for the key to use, i.e use this as key in the resulting map instead.
  - `type: field_type()`: validate that the field has the given type.
  - `required: boolean()`: set to true if the field is required.
  - `default: any()`: use as default value if missing.
  """
  @spec parse_map(map(), [field()], keyword()) :: {:ok, map()} | {:error, any()}
  def parse_map(from, fields, options \\ []) when is_map(from) do
    with :ok <- validate_strict(from, fields, Keyword.get(options, :strict, false)),
         {:ok, result} <- reduce_map(from, fields) do
      {:ok, result}
    else
      err -> err
    end
  end

  defp validate_strict(_from, _fields, false), do: :ok

  defp validate_strict(from, fields, true) do
    field_names =
      fields
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()

    unknown =
        Map.keys(from)
        |> Enum.find(fn key -> not MapSet.member?(field_names, key) end)

    case unknown do
      nil -> :ok
      _ -> {:error, "unknown key: #{unknown}"}
    end
  end

  defp reduce_map(from, fields) do
    result = Enum.reduce_while(fields, %{}, fn {key, opts}, acc ->
      required = Keyword.get(opts, :required)
      default = Keyword.get(opts, :default, nil)

      case Map.get(from, key) do
        nil -> if required do
            err = "missing required key: #{key}"
            {:halt, Map.put(acc, @error_key, err)}
          else
            {:cont, Map.put(acc, key, default)}
          end
        value ->
          key = Keyword.get(opts, :into, key)
          type = Keyword.get(opts, :type)
          put_field(acc, key, value, type)
      end
    end)

    case Map.get(result, @error_key) do
      nil -> {:ok, result}
      err -> {:error, err}
    end
  end

  defp put_field(acc, key, value, nil) do
    {:cont, Map.put(acc, key, value)}
  end

  defp put_field(acc, key, value, :int) when is_integer(value) do
    {:cont, Map.put(acc, key, value)}
  end

  defp put_field(acc, key, value, :string) when is_binary(value) do
    {:cont, Map.put(acc, key, value)}
  end

  defp put_field(acc, key, value, :map) when is_map(value) do
    {:cont, Map.put(acc, key, value)}
  end

  defp put_field(acc, key, _value, expected_type) do
    err = "invalid type for #{key}: expected #{expected_type}"
    {:halt, Map.put(acc, @error_key, err)}
  end
end

