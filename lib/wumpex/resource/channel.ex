defmodule Wumpex.Resource.Channel do
  import Wumpex.Resource

  alias Wumpex.Resource
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

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          type: channel_type(),
          guild_id: Resource.snowflake(),
          position: non_neg_integer()
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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:recipients, nil, fn recipients -> to_structs(recipients, User) end)
      |> Map.update(:last_pin_timestamp, nil, &to_datetime/1)

    struct(__MODULE__, data)
  end
end
