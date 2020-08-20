defmodule Wumpex.Resource.VoiceState do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Guild.Member

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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:member, nil, &Member.to_struct/1)

    struct(__MODULE__, data)
  end
end
