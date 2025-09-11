defmodule Blast.Probe do
  @moduledoc false

  @callback probe(String.t()) :: :ok | {:error, any()}
end
