defmodule Blast.MixProject do
  use Mix.Project

  def project do
    [
      app: :blast,
      version: "0.5.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        blast: [
          steps: [:assemble, &Burrito.wrap/1],
          burrito: [
            targets: [
              linux: [os: :linux, cpu: :x86_64]
            ]
          ]
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
      {:yaml_elixir, "~> 2.0"},
      {:burrito, "~> 1.0"}
    ]
  end
end
