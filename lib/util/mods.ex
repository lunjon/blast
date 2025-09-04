defmodule Util.Mods do
  # Utility functions for working with modules,
  # such as trying to invoke callbacks from the blastfile.
  @moduledoc false

  @doc """
  Tries to invoke an experted function in the module.
  Returns `{:ok, ret}` where `ret` is the return value of the function
  if it succeeded. If the function wasn't exported it returns `{:error, dynamic()}`.
  """
  @spec invoke(module(), atom(), integer(), list()) :: {:ok, dynamic()} | {:error, dynamic()}
  def invoke(mod, fname, arity, args \\ []) do
    if function_exported?(mod, fname, arity) do
      ret = apply(mod, fname, args)
      {:ok, ret}
    else
      {:error, "module missing exported function: #{fname}/#{arity}"}
    end
  end
end
