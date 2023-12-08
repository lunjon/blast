defmodule Core.Format do
  @type format :: :json | :plain

  @spec format_result(Blast.Result.t(), format()) :: binary()
  def format_result(result, :json) do
    {:ok, json} =
      Jason.encode(
        %{
          responses: result.responses
        },
        pretty: true
      )

    json
  end

  def format_result(_result, :plain) do
    "NOT IMPLEMENTED"
  end

  def format_result(_result, fmt) do
    {:error, "invalid format type: #{fmt}"}
  end
end
