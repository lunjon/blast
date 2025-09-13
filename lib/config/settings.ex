defmodule Blast.Settings do
  @moduledoc """
  Settings defines more specifing options for the configuration.
  """

  alias __MODULE__, as: Self
  alias Blast.Util.Parser

  @type control_kind :: :default | :rampup

  @type control :: %{
          kind: control_kind(),
          properties: nil | map()
        }

  @type t :: %__MODULE__{
          control: nil | control()
        }

  defstruct control: %{kind: :default, props: nil}

  def parse(nil), do: {:ok, %Self{}}

  def parse(settings) when is_map(settings) do
    with {:ok, kind, props} <- parse_control(settings[:control]),
         {:ok, control} <- parse_control_kind(kind, props) do
      {:ok, %Self{control: control}}
    else
      {:error, err} -> {:error, err}
    end
  end

  def parse(_settings), do: {:error, "invalid type for settings: expected map"}

  defp parse_control(nil), do: {:ok, :default, nil}

  defp parse_control(%{kind: kind, properties: props}) do
    {:ok, kind, props}
  end

  defp parse_control(control) do
    {:error, "invalid control setting: #{inspect(control)}"}
  end

  defp parse_control_kind(:default, _props) do
    {:ok, %{kind: :default, props: nil}}
  end

  defp parse_control_kind("rampup", props) do
    fields = [
      {:every, into: :every, type: :int, required: true},
      {:add, into: :add, type: :int, default: 1, min: 1, max: 100},
      {:start, into: :start, type: :int, required: true, min: 1, max: 100},
      {:target, into: :target, type: :int, required: true, min: 5, max: 1000}
    ]

    props = Parser.parse_map(props, fields, strict: true)

    case props do
      {:ok, props} -> {:ok, %{kind: :rampup, props: props}}
      err -> err
    end
  end

  defp parse_control_kind(kind, _props) do
    {:error, "invalid control kind: #{inspect(kind)}\n    Valid control kinds are: rampup"}
  end
end
