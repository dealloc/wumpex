defmodule Wumpex.Resource.VoiceState do
  @moduledoc """
  Represents a user's voice connection status.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/voice#voice-state-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Guild.Member

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:guild_id` - The ID of the guild this voice state is for.
  * `:channel_id` - The channel ID this user is connected to.
  * `:user_id` - The ID of the user this voice state is for.
  * `:member` - The guild member this voice state is for.
  * `:session_id` - The session ID for this voice state.
  * `:deaf` - Whether this user is deafened by the server.
  * `:mute` - Whether this user is muted by the server.
  * `:self_deaf` - Whether this user has deafened himself.
  * `:self_mute` - Whether this user has muted himself.
  * `:self_stream` - Whether this user is streaming using "Go Live".
  * `:self_video` - Whether this user's camera is enabled.
  * `:suppress` - Whether this user is muted by the current user.
  """
  @type t :: %__MODULE__{
          guild_id: Resource.snowflake(),
          channel_id: Resource.snowflake(),
          user_id: Resource.snowflake(),
          member: Member.t(),
          session_id: String.t(),
          deaf: boolean(),
          mute: boolean(),
          self_deaf: boolean(),
          self_mute: boolean(),
          self_stream: boolean(),
          self_video: boolean(),
          suppress: boolean()
        }

  defstruct [
    :guild_id,
    :channel_id,
    :user_id,
    :member,
    :session_id,
    :deaf,
    :mute,
    :self_deaf,
    :self_mute,
    :self_stream,
    :self_video,
    :suppress
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.VoiceState.to_struct(%{})
      %Wumpex.Resource.VoiceState{}
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:member, nil, &Member.to_struct/1)

    struct(__MODULE__, data)
  end
end
