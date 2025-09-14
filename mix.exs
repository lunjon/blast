defmodule Blast.MixProject do
  use Mix.Project

  def project do
    [
      app: :blast,
      version: "0.10.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        extras: ["README.md"]
      ],
      escript: [main_module: Blast.CLI],
      releases: [
        blast: [
          include_executables_for: [:unix],
          applications: [blast: :permanent]
        ]
      ],
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_ignore_apps: [:mnesia]
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38.3", only: :dev, runtime: false}
    ]
  end
end
