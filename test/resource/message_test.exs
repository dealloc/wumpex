defmodule Wumpex.Resource.MessageTest do
  use ExUnit.Case
  alias Wumpex.Resource.Message
  alias Wumpex.Resource.User
  alias Wumpex.Resource.Message.Reaction
  alias Wumpex.Resource.Emoji
  alias Wumpex.Resource.ChannelMention
  alias Wumpex.Resource.Message.Reference

  describe "to_struct/1 should" do
    test "parse the official example for message" do
      example = %{
        "attachments" => [],
        "author" => %{
          "avatar" => "a_bab14f271d565501444b2ca3be944b25",
          "discriminator" => "9999",
          "id" => "53908099506183680",
          "username" => "Mason"
        },
        "channel_id" => "290926798999357250",
        "content" => "Supa Hot",
        "edited_timestamp" => nil,
        "embeds" => [],
        "id" => "334385199974967042",
        "mention_everyone" => false,
        "mention_roles" => [],
        "mentions" => [],
        "pinned" => false,
        "reactions" => [
          %{"count" => 1, "emoji" => %{"id" => nil, "name" => "🔥"}, "me" => false}
        ],
        "timestamp" => "2017-07-11T17:27:07.299000+00:00",
        "tts" => false,
        "type" => 0
      }

      assert %Message{
        attachments: [],
        author: %User{
          avatar: "a_bab14f271d565501444b2ca3be944b25",
          discriminator: "9999",
          id: "53908099506183680",
          username: "Mason"
        },
        channel_id: "290926798999357250",
        content: "Supa Hot",
        edited_timestamp: nil,
        embeds: [],
        id: "334385199974967042",
        mention_everyone: false,
        mention_roles: [],
        mentions: [],
        pinned: false,
        reactions: [
          %Reaction{count: 1, emoji: %Emoji{id: nil, name: "🔥"}, me: false}
        ],
        timestamp: ~U[2017-07-11 17:27:07.299000Z],
        tts: false,
        type: 0
      } = Message.to_struct(example)
    end

    test "parse the official example for crossposted message" do
      example = %{
        "attachments" => [],
        "author" => %{
          "avatar" => "a_bab14f271d565501444b2ca3be944b25",
          "discriminator" => "9999",
          "id" => "53908099506183680",
          "username" => "Mason"
        },
        "channel_id" => "290926798999357250",
        "content" => "Big news! In this <#278325129692446722> channel!",
        "edited_timestamp" => nil,
        "embeds" => [],
        "flags" => 2,
        "id" => "334385199974967042",
        "mention_channels" => [
          %{
            "guild_id" => "278325129692446720",
            "id" => "278325129692446722",
            "name" => "big-news",
            "type" => 5
          }
        ],
        "mention_everyone" => false,
        "mention_roles" => [],
        "mentions" => [],
        "message_reference" => %{
          "channel_id" => "278325129692446722",
          "guild_id" => "278325129692446720",
          "message_id" => "306588351130107906"
        },
        "pinned" => false,
        "reactions" => [
          %{"count" => 1, "emoji" => %{"id" => nil, "name" => "🔥"}, "me" => false}
        ],
        "timestamp" => "2017-07-11T17:27:07.299000+00:00",
        "tts" => false,
        "type" => 0
      }

      assert %Message{
        attachments: [],
        author: %User{
          avatar: "a_bab14f271d565501444b2ca3be944b25",
          discriminator: "9999",
          id: "53908099506183680",
          username: "Mason"
        },
        channel_id: "290926798999357250",
        content: "Big news! In this <#278325129692446722> channel!",
        edited_timestamp: nil,
        embeds: [],
        id: "334385199974967042",
        mention_channels: [
          %ChannelMention{
            guild_id: "278325129692446720",
            id: "278325129692446722",
            name: "big-news",
            type: 5
          }
        ],
        mention_everyone: false,
        mention_roles: [],
        mentions: [],
        message_reference: %Reference{
          channel_id: "278325129692446722",
          guild_id: "278325129692446720",
          message_id: "306588351130107906"
        },
        pinned: false,
        reactions: [
          %Reaction{count: 1, emoji: %Emoji{id: nil, name: "🔥"}, me: false}
        ],
        timestamp: ~U[2017-07-11 17:27:07.299000Z],
        tts: false,
        type: 0
      } = Message.to_struct(example)
    end
  end
end
