defmodule Core.Worker.Config do
  @moduledoc """
  Defines the input to a worker describing how to send the requests,
  and some additional metadata around the state of the runners.
  """

  @typedoc """
  Hooks are used to enrich the request before sending it.
  """
  @type hook :: (map(), Core.Request.t() -> {map(), Core.Request.t()})

  @type t :: %{
          workers: integer(),
          frequency: integer(),
          request: Core.Request.t(),
          bucket: pid(),
          pre_request: pid()
        }

  defstruct workers: 1,
            frequency: 0,
            request: nil,
            bucket: nil,
            hooks: %{}

  @doc """
  Sets the pre-request hook.
  Override the default before_hook function.
  """
  @spec set_pre_request_hook(t(), hook()) :: t()
  def set_pre_request_hook(config, hook) do
    Map.put(config, :pre_request, hook)
  end
end
