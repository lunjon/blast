defmodule Blast.Worker.Config do
  alias Blast.{Hooks, Request}

  @moduledoc """
  Defines the input to a worker describing how to send the requests,
  and some additional metadata around the state of the runners.
  """

  @type t :: %__MODULE__{
    workers: integer(),
    frequency: integer(),
    requests: [Request.t()],
    bucket: pid(),
    hooks: Hooks.t(),
  }

  defstruct workers: 1,
            frequency: 0,
            requests: [],
            bucket: nil,
            hooks: %Hooks{}
end
