defmodule Wumpex.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :wumpex,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: [
        groups_for_modules: [
          Base: [
            Wumpex.Base.Websocket,
            Wumpex.Base.Distributed
          ],
          Gateway: [
            Wumpex.Gateway,
            Wumpex.Gateway.Worker,
            Wumpex.Gateway.State,
            Wumpex.Gateway.Opcodes,
            Wumpex.Gateway.EventHandler
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
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:websocket_client, "~> 1.4"},
      {:socket, "~> 0.3", only: [:test]},
      {:httpoison, "~> 1.6"}
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
