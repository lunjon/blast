defmodule CLI.MixProject do
  use Mix.Project

  def project do
    [
      app: :cli,
      version: "0.1.0",
        build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      aliases: aliases()
    ]
  end

  def escript() do
    [
      main_module: Blast.CLI
    ]
  end

  defp aliases do
    [
      all: ["compile", "format", "escript.build"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:core, in_umbrella: true},
    ]
  end
end
