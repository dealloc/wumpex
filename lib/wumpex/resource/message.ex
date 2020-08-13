defmodule Wumpex.Resource.Message do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.User
  alias Wumpex.Resource.GuildMember
  alias Wumpex.Resource.ChannelMention
  alias Wumpex.Resource.Attachment
  alias Wumpex.Resource.Embed
  alias Wumpex.Resource.MessageReaction
  alias Wumpex.Resource.MessageActivity
  alias Wumpex.Resource.MessageApplication
  alias Wumpex.Resource.MessageReference

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          channel_id: Resource.snowflake(),
          guild_id: Resource.snowflake(),
          author: User.t(),
          member: GuildMember.t(),
          content: String.t(),
          timestamp: DateTime.t(),
          edited_timestamp: DateTime.t(),
          tts: boolean(),
          mention_everyone: boolean(),
          mentions: [User.t()],
          mention_roles: [String.t()],
          mention_channels: [ChannelMention.t()],
          attachments: [Attachment.t()],
          embeds: [Embed.t()],
          reactions: [MessageReaction.t()],
          nonce: String.t(),
          pinned: boolean(),
          webhook_id: Resource.snowflake(),
          type: non_neg_integer(),
          activity: MessageActivity.t(),
          application: MessageApplication.t(),
          message_reference: MessageReference.t(),
          flags: non_neg_integer()
        },
    reactions: [MessageReaction.t()]

  defstruct [
    :id,
    :channel_id,
    :guild_id,
    :author,
    :member,
    :content,
    :timestamp,
    :edited_timestamp,
    :tts,
    :mention_everyone,
    :mentions,
    :mention_roles,
    :mention_channels,
    :attachments,
    :embeds,
    :reactions,
    :nonce,
    :pinned,
    :webhook_id,
    :type,
    :activity,
    :application,
    :message_reference,
    :flags
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:author, nil, &User.to_struct/1)
      |> Map.update(:member, nil, &GuildMember.to_struct/1)
      |> Map.update(:timestamp, nil, &to_datetime/1)
      |> Map.update(:edited_timestamp, nil, &to_datetime/1)
      |> Map.update(:mentions, nil, fn mentions -> to_structs(mentions, User) end)
      |> Map.update(:mention_channels, nil, fn mention_channels -> to_structs(mention_channels, ChannelMention) end)
      |> Map.update(:attachments, nil, fn attachments -> to_structs(attachments, Attachment) end)
      |> Map.update(:embeds, nil, fn embeds -> to_structs(embeds, Embed) end)
      |> Map.update(:reactions, nil, fn reactions -> to_structs(reactions, MessageReaction) end)
      |> Map.update(:nonce, nil, &to_string/1)
      |> Map.update(:activity, nil, fn activity -> to_structs(activity, MessageActivity) end)
      |> Map.update(:application, nil, fn application -> to_structs(application, MessageApplication) end)
      |> Map.update(:message_references, nil, fn messages_references -> to_structs(messages_references, MessageReaction) end)

      struct!(__MODULE__, data)
  end
end
