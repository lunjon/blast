defmodule Blast.Config do
  use Agent
  alias Blast.{Hooks, Request, Settings}

  alias __MODULE__, as: Self

  @type t() :: %Self{
          requests: [Request.t()],
          hooks: Hooks.t(),
          bucket: nil | pid(),
          settings: Settings.t()
        }

  @moduledoc false

  @enforce_keys [:requests, :hooks, :settings]
  defstruct [:requests, :hooks, :bucket, :settings]

  @doc """
  Returns the expanded list of requests with respect to their weights.
  """
  @spec normalized_requests(t()) :: [Request.t()]
  def normalized_requests(%Self{requests: requests}) do
    requests
    |> Enum.map(fn req ->
      case req.weight do
        nil -> [req]
        n -> List.duplicate(req, n)
      end
    end)
    |> Enum.flat_map(& &1)
    |> Enum.shuffle()
  end
end
