defmodule Blast.Worker.Config do
  @moduledoc """
  Defines the input to a worker describing how to send the requests,
  and some additional metadata around the state of the runners.
  """

  @typedoc """
  Hooks are used to enrich the request before sending it.
  """

  alias Blast.Request

  @type hook :: (map(), Request.t() -> {map(), Request.t()})

  @type t :: %{
          workers: integer(),
          frequency: integer(),
          requests: [Request.t()],
          bucket: pid(),
          on_request: pid()
        }

  defstruct workers: 1,
            frequency: 0,
            requests: [],
            bucket: nil,
            hooks: %{}

  @doc """
  Sets the on_request hook, which is called before
  each request is sent.
  """
  @spec set_on_request_hook(t(), hook()) :: t()
  def set_on_request_hook(config, hook) do
    Map.put(config, :on_request, hook)
  end
end
