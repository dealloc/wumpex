defmodule Wumpex.Resource.GuildMember do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.User

  @type t :: %__MODULE__{
          user: User.t(),
          nick: String.t(),
          roles: [Resource.snowflake()],
          joined_at: DateTime.t(),
          premium_since: DateTime.t(),
          deaf: boolean(),
          mute: boolean()
        }

  defstruct [
    :user,
    :nick,
    :roles,
    :joined_at,
    :premium_since,
    :deaf,
    :mute
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:joined_at, nil, &Resource.to_datetime/1)
      |> Map.update(:premium_since, nil, &Resource.to_datetime/1)

    struct!(__MODULE__, data)
  end
end
