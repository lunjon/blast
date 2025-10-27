defmodule Blast.MixProject do
  use Mix.Project

  def project do
    [
      app: :blast,
      version: "0.10.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Blast.CLI],
      elixirc_paths: elixirc_paths(Mix.env()),
      releases: [
        blast: [
          include_executables_for: [:unix],
          applications: [blast: :permanent]
        ]
      ],
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Blast.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.2"},
      {:plug_cowboy, "~> 2.0"},
      {:ex_doc, "~> 0.39.1", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]
end
