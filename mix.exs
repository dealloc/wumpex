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
          Base: [
            Wumpex.Base.Coordinator,
            Wumpex.Base.Distributed,
            Wumpex.Base.Websocket
          ],
          Gateway: [
            Wumpex.Gateway,
            Wumpex.Gateway.Worker,
            Wumpex.Gateway.State,
            Wumpex.Gateway.Opcodes,
            Wumpex.Gateway.EventHandler
          ],
          Resources: [
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
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:socket, "~> 0.3", only: [:test]},
      {:fake_server, "~> 2.1", only: [:test]},
      {:websocket_client, "~> 1.4"},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.2"}
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
