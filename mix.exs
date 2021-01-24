defmodule Wumpex.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :wumpex,
      source_url: "https://github.com/dealloc/wumpex",
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: [
        groups_for_modules: [
          Api: [
            ~r/Wumpex.Api/
          ],
          Base: [
            ~r/Wumpex.Base/
          ],
          Gateway: [
            ~r/Wumpex.Gateway/
          ],
          Voice: [
            ~r/Wumpex.Voice/
          ],
          Resources: [
            ~r/Wumpex.Resource/
          ],
          Sharding: [
            ~r/Wumpex.Sharding/
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wumpex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:socket, "~> 0.3", only: [:test]},
      {:fake_server, "~> 2.1", only: [:test]},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.2"},
      {:poolboy, "~> 1.5"},
      {:syn, "~> 2.1", optional: true},
      {:gun, "~> 1.3"},
      {:gen_stage, "~> 1.0"},
      {:telemetry, "~> 0.4"},
      {:manifold, "~> 1.4"},
      {:kcl, "~> 1.3"},
      # Both Gun and FakeServer require cowlib, so we have to override it to keep Mix happy.
      {:cowlib, "~> 2.9.1", override: true}
    ]
  end

  # Mix aliases
  defp aliases do
    [
      setup: ["deps.get", "dialyzer", "docs"],
      analysis: ["dialyzer", "credo"]
    ]
  end
end
