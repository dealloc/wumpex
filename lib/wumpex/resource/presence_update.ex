defmodule Wumpex.Resource.PresenceUpdate do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Activity
  alias Wumpex.Resource.ClientStatus
  alias Wumpex.Resource.User

  @type t :: %__MODULE__{
          user: User.t(),
          roles: [Resource.snowflake()],
          game: Activity.t(),
          guild_id: Resource.snowflake(),
          status: ClientStatus.status(),
          activities: [Activity.t()],
          client_status: ClientStatus.t(),
          premium_since: DateTime.t(),
          nick: String.t()
        }

  defstruct [
    :user,
    :roles,
    :game,
    :guild_id,
    :status,
    :activities,
    :client_status,
    :premium_since,
    :nick
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:user, nil, &User.to_struct/1)
      |> Map.update(:game, nil, &Activity.to_struct/1)
      |> Map.update(:activities, nil, fn activities -> to_structs(activities, Activity) end)
      |> Map.update(:client_status, nil, &ClientStatus.to_struct/1)
      |> Map.update(:premium_since, nil, &to_datetime/1)

    struct!(__MODULE__, data)
  end
end
