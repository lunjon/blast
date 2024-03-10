defmodule Blast.MixProject do
  use Mix.Project

  def project do
    [
      app: :blast,
      version: "0.5.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Blast.Main],
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
      {:logger_backends, "~> 1.0"},
      {:logger_file_backend, "~> 0.0"},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
