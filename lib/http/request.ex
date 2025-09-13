defmodule Blast.Request do
  @moduledoc """
  Request defines a request model for Blast.
  """

  @type t :: %__MODULE__{
          method: atom(),
          url: String.t(),
          headers: map(),
          body: any(),
          weight: non_neg_integer()
        }

  @enforce_keys [:method, :url, :headers]
  defstruct [:method, :url, :headers, :body, :weight]

  alias __MODULE__

  def new(method, url, headers \\ %{}, body \\ nil) do
    %Request{
      method: method,
      url: url,
      headers: headers,
      body: body,
      weight: 1
    }
  end

  def get(url, headers \\ %{}), do: new(:get, url, headers)

  def post(url, body, headers \\ %{}) do
    new(:get, url, headers, body)
  end

  def put_header(
        %Request{headers: headers} = req,
        name,
        value
      ) do
    headers = Map.put(headers, name, value)
    Map.put(req, :headers, headers)
  end

  def equals(%Request{url: url1, method: method1}, %Request{url: url2, method: method2}) do
    url1 == url2 and method1 == method2
  end
end
