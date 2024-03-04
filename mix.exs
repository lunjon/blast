defmodule Blast.MixProject do
  use Mix.Project

  def project do
    [
      app: :blast,
      version: "0.5.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Blast.CLI],
      releases: [
        blast: [
          include_executables_for: [:unix],
          applications: [blast: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Blast.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:logger_backends, "~> 1.0"},
      {:logger_file_backend, "~> 0.0"},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.0"}
    ]
  end
end
