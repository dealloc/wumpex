defmodule Wumpex.Resource.Message do
  @moduledoc """
  Represents a message sent in a channel within Discord.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#message-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Attachment
  alias Wumpex.Resource.ChannelMention
  alias Wumpex.Resource.Embed
  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.Message.Activity
  alias Wumpex.Resource.Message.Application
  alias Wumpex.Resource.Message.Reaction
  alias Wumpex.Resource.Message.Reference
  alias Wumpex.Resource.User

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the message.
  * `:channel_id` - The ID of the channel the message was sent in.
  * `:guild_id` - The ID of the guild the message was sent in.
  * `:author` - The author of this message (not guaranteerd to be a valid user).
  * `:member` - Member properties for the message author.
  * `:content` - The contents of the message.
  * `:timestamp` - The timestamp when this message was sent.
  * `:edited_timestamp` - When this message was edited (set to `nil` if it's never been edited).
  * `:tts` - Whether this was a TTS message.
  * `:mention_everyone` - Whether this message mentions everyone.
  * `:mentions` - An array of `Wumpex.Resource.User` objects mentioned in this message.
  * `:mention_roles` - A list of role IDs specifically mentioned in this message.
  * `:mention_channels` - lis of `Wumpex.Resource.ChannelMention` specifically mentioned in this message.
  * `:attachments` - Any attached files.
  * `:embeds` - Any embedded content.
  * `:reactions` - A list of `Wumpex.Resource.Message.Reaction` reacted to this message.
  * `:nonce` - A unique nonce, can be used for validating the message was sent.
  * `:pinned` - Whether this message is pinned.
  * `:webhook_id` - The ID of the webhook, if it was generated by one.
  * `:type` - The `t:message_type/0`.
  * `:activity` - A `Wumpex.Resource.Activity` object, sent with rich presence related chat embeds.
  * `:application` - sent with rich presence related chat embeds.
  * `:message_reference` - Reference data sent with crossposted messages.
  * `:flags` - Message flags, describes extra features of the message.
  """
  @type t :: %__MODULE__{
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
          type: message_type(),
          activity: Activity.t(),
          application: Application.t(),
          message_reference: Reference.t(),
          flags: non_neg_integer()
        }

  @typedoc """
  The type of message.

  Can have the following values:
  * `0` - Regular message.
  * `1` - Recipient was added.
  * `2` - Recipient was removed.
  * `3` - Call started.
  * `4` - Channel name changed.
  * `5` - Channel icon changed.
  * `6` - Channel message was pinned.
  * `7` - A guild member joined.
  * `8` - User boosted the server.
  * `9` - A user boosted the server to tier 1.
  * `10` - A user boosted the server to tier 2.
  * `11` - A user boosted the server to tier 3.
  * `12` - A channel follow add.
  * `14` - Guild discovery disqualified.
  * `15` - Guild discovery re-qualified.
  """
  @type message_type :: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 14 | 15

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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Message.to_struct(%{})
      %Wumpex.Resource.Message{}
  """
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
