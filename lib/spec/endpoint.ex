defmodule Blast.Spec.Endpoint do
  @moduledoc false

  @type t :: %__MODULE__{base_url: String.t(), requests: [Blast.Request.t()]}

  @enforce_keys [:base_url, :requests]
  defstruct base_url: "", requests: []
end
