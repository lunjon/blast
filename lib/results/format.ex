defmodule Blast.Format do
  @moduledoc false

  @type format :: :json | :plain

  @spec format_result(Blast.Result.t(), format()) :: binary()
  def format_result(result, :json) do
    JSON.encode!(%{
      responses: result.responses
    })
  end

  def format_result(_result, :plain) do
    "NOT IMPLEMENTED"
  end

  def format_result(_result, fmt) do
    {:error, "invalid format type: #{fmt}"}
  end
end
