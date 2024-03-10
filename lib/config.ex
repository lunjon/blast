defmodule Blast.Config do
  alias Blast.{Hooks, Request}

  @moduledoc """
  TODO.
  """

  @type t :: %__MODULE__{
    frequency: integer(),
    requests: [Request.t()],
    bucket: pid(),
    hooks: Hooks.t(),
  }

  defstruct frequency: 0,
            requests: [],
            bucket: nil,
            hooks: %Hooks{}
end

