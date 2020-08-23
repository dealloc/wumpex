defmodule Wumpex.Resource.Channel do
  @moduledoc """
  Represents a guild or DM channel within Discord.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Channel.Overwrite
  alias Wumpex.Resource.User

  @typedoc """
    the type of channel

    Can have the following values:
    - `0` (*GUILD_TEXT*) - A text channel withing a server.
    - `1` (*DM*) - A direct message between users.
    - `2` (*GUILD_VOICE*) - A voice channel within a server.
    - `3` (*GROUP_DM*) - A direct message between multiple users.
    - `4` (*GUILD_CATEGORY*) - An [organizational category](https://support.discord.com/hc/en-us/articles/115001580171-Channel-Categories-101) that contains up to 50 channels.
    - `5` (*GUILD_NEWS*) - A channel that [users can follow and crosspost into their own server](https://support.discord.com/hc/en-us/articles/360032008192).
    - `6` (*GUILD_STORE*) - A channel in which game developers can [sell their game on Discord](https://discord.com/developers/docs/game-and-server-management/special-channels).
  """
  @type channel_type :: 0 | 1 | 2 | 3 | 4 | 5 | 6

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the channel.
  * `:type` - The `t:channel_type/0` of the channel.
  * `:guild_id` - The ID of the guild.
  * `:position` - The sorting position of the channel.
  * `:permission_overwrites` - Explicit permission overwrites for members and roles.
  * `:name` - The name of the channel (2-100 characters).
  * `:topic` - The channel topic (0-1024 characters).
  * `:nsfw` - Whether the channel is NSFW.
  * `:last_message_id` - The ID of the last message sent in this channel (may not point to an existing or valid message).
  * `:bitrate` - The bitrate (in bits) of the voice channel.
  * `:user_limit` - The user limit of the voice channel.
  * `:rate_limit_per_user` - The amount of seconds a user has to wait before sending another message (between 0 and 21600); bots, users with the `manage_messages` or `manage_channel` are unaffected.
  * `:recipients` a list of `Wumpex.Resource.User` that are the recipients of the DM.
  * `:icon` The icon hash.
  * `:owner_id` - The ID of the DM creator.
  * `:application_id` - The application ID of the DM creator, if it's bot-created.
  * `:parent_id` - ID of the parent category for a channel (each parent category can contain up to 50 channels).
  * `:last_pin_timestamp` - When the last pinned message was pinned.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          type: channel_type(),
          guild_id: Resource.snowflake(),
          position: non_neg_integer(),
          permission_overwrites: [Overwrite.t()],
          name: String.t(),
          topic: String.t(),
          nsfw: boolean(),
          last_message_id: Resource.snowflake(),
          bitrate: non_neg_integer(),
          user_limit: non_neg_integer(),
          rate_limit_per_user: non_neg_integer(),
          recipients: [User.t()],
          icon: String.t(),
          owner_id: Resource.snowflake(),
          application_id: Resource.snowflake(),
          parent_id: Resource.snowflake(),
          last_pin_timestamp: DateTime.t()
        }

  defstruct [
    :id,
    :type,
    :guild_id,
    :position,
    :permission_overwrites,
    :name,
    :topic,
    :nsfw,
    :last_message_id,
    :bitrate,
    :user_limit,
    :rate_limit_per_user,
    :recipients,
    :icon,
    :owner_id,
    :application_id,
    :parent_id,
    :last_pin_timestamp
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Channel.to_struct(%{})
      %Wumpex.Resource.Channel{
        id: nil,
        type: nil,
        guild_id: nil,
        position: nil,
        permission_overwrites: nil,
        name: nil,
        topic: nil,
        nsfw: nil,
        last_message_id: nil,
        bitrate: nil,
        user_limit: nil,
        rate_limit_per_user: nil,
        recipients: nil,
        icon: nil,
        owner_id: nil,
        application_id: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:permission_overwrites, nil, &to_structs(&1, Overwrite))
      |> Map.update(:recipients, nil, &to_structs(&1, User))
      |> Map.update(:last_pin_timestamp, nil, &to_datetime/1)

    struct(__MODULE__, data)
  end
end
