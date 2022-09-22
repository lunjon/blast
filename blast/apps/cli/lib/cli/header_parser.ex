defmodule Blast.CLI.HeaderParser do
  @keyvalue_regex ~r/^([a-zA-Z][a-zA-Z-]*[a-zA-Z]?):\s?(.+)$/
  # Parsing of "key: value" type options (--header and --data-form)

  def parse_keyvalues([], map), do: {:ok, map}

  def parse_keyvalues([head | tail], map) do
    {_, header} = head

    case parse_keyvalue(header) do
      {:error, _msg} = err ->
        err

      {:ok, name, value} ->
        {_, hs} =
          Map.get_and_update(map, name, fn
            nil -> {value, value}
            current -> {value, "#{current}; #{value}"}
          end)

        parse_keyvalues(tail, hs)
    end
  end

  def parse_keyvalue(header) when is_binary(header) do
    Regex.run(@keyvalue_regex, header)
    |> handle_keyvalue_match()
  end

  defp handle_keyvalue_match([_header, name, value]) do
    {:ok, name, value}
  end

  defp handle_keyvalue_match(nil) do
    {:error, "invalid format"}
  end
end
