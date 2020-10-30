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
            Wumpex.Api,
            Wumpex.Api.Ratelimit,
            Wumpex.Api.Ratelimit.Bucket,
            Wumpex.Api.Ratelimit.StatelessBucket,
            Wumpex.Api.Ratelimit.Well
          ],
          Base: [
            Wumpex.Base.Coordinator,
            Wumpex.Base.Distributed,
            Wumpex.Base.Ledger,
            Wumpex.Base.Websocket
          ],
          Gateway: [
            Wumpex.Gateway,
            Wumpex.Gateway.Worker,
            Wumpex.Gateway.Opcodes
          ],
          Resources: [
            Wumpex.Resource,
            Wumpex.Resource.Activity,
            Wumpex.Resource.Activity.Assets,
            Wumpex.Resource.Activity.Emoji,
            Wumpex.Resource.Activity.Flags,
            Wumpex.Resource.Activity.Party,
            Wumpex.Resource.Activity.Secrets,
            Wumpex.Resource.Activity.Timestamps,
            Wumpex.Resource.Attachment,
            Wumpex.Resource.Channel,
            Wumpex.Resource.Channel.Overwrite,
            Wumpex.Resource.ChannelMention,
            Wumpex.Resource.ClientStatus,
            Wumpex.Resource.Embed,
            Wumpex.Resource.Embed.Author,
            Wumpex.Resource.Embed.Field,
            Wumpex.Resource.Embed.Footer,
            Wumpex.Resource.Embed.Image,
            Wumpex.Resource.Embed.Provider,
            Wumpex.Resource.Embed.Thumbnail,
            Wumpex.Resource.Embed.Video,
            Wumpex.Resource.Emoji,
            Wumpex.Resource.Guild,
            Wumpex.Resource.Guild.ChannelFlags,
            Wumpex.Resource.Guild.Member,
            Wumpex.Resource.Message,
            Wumpex.Resource.Message.Activity,
            Wumpex.Resource.Message.Application,
            Wumpex.Resource.Message.Reaction,
            Wumpex.Resource.Message.Reference,
            Wumpex.Resource.PresenceUpdate,
            Wumpex.Resource.Role,
            Wumpex.Resource.User,
            Wumpex.Resource.UserFlags,
            Wumpex.Resource.VoiceState
          ],
          Sharding: [
            Wumpex.Sharding,
            Wumpex.Sharding.ShardLedger
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
