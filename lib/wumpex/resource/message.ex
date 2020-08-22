defmodule Wumpex.Resource.Message do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.User
  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.ChannelMention
  alias Wumpex.Resource.Attachment
  alias Wumpex.Resource.Embed
  alias Wumpex.Resource.Message.Reaction
  alias Wumpex.Resource.Message.Activity
  alias Wumpex.Resource.Message.Application
  alias Wumpex.Resource.Message.Reference

  @type(
    t :: %__MODULE__{
      id: Resource.snowflake(),
      channel_id: Resource.snowflake(),
      guild_id: Resource.snowflake(),
      author: User.t(),
      member: Member.t(),
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
      reactions: [Reaction.t()],
      nonce: String.t(),
      pinned: boolean(),
      webhook_id: Resource.snowflake(),
      type: non_neg_integer(),
      activity: Activity.t(),
      application: Application.t(),
      message_reference: Reference.t(),
      flags: non_neg_integer()
    },
    reactions: [Reaction.t()]
  )

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
      |> Map.update(:member, nil, &Member.to_struct/1)
      |> Map.update(:timestamp, nil, &to_datetime/1)
      |> Map.update(:edited_timestamp, nil, &to_datetime/1)
      |> Map.update(:mentions, nil, &to_structs(&1, User))
      |> Map.update(:mention_channels, nil, &to_structs(&1, ChannelMention))
      |> Map.update(:attachments, nil, &to_structs(&1, Attachment))
      |> Map.update(:embeds, nil, &to_structs(&1, Embed))
      |> Map.update(:reactions, nil, &to_structs(&1, Reaction))
      |> Map.update(:nonce, nil, &to_string/1)
      |> Map.update(:activity, nil, &to_structs(&1, Activity))
      |> Map.update(:application, nil, &to_structs(&1, Application))
      |> Map.update(:message_reference, nil, &Reference.to_struct/1)

    struct(__MODULE__, data)
  end
end
