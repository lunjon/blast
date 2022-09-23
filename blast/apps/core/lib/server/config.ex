defmodule Core.WorkerConfig do
  @typedoc """
  WorkerConfig defines the input to a worker
  describing how to send the requests.
  """
  @type t :: %{
          frequency: integer,
          request: HTTPoison.Request.t()
        }

  defstruct frequency: 0, request: nil
end
