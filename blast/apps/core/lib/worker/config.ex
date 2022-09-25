defmodule Core.Worker.Config do
  @moduledoc """
  Defines the input to a worker describing how to send the requests,
  and some additional metadata around the state of the runners.
  """

  @type t :: %{
          workers: integer(),
          frequency: integer(),
          request: HTTPoison.Request.t(),
          results_bucket: pid()
        }

  defstruct workers: 1, frequency: 0, request: nil, results_bucket: nil
end
