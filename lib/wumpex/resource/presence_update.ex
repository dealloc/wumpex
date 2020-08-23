defmodule Wumpex.Resource.PresenceUpdate do
  @moduledoc """
  > A user's presence is their current state on a guild.
  > This event is sent when a user's presence or info, such as name or avatar, is updated.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#presence-update).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Activity
  alias Wumpex.Resource.ClientStatus
  alias Wumpex.Resource.User

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:user` - The user whose presence is being updated.
  * `:roles` - The roles this user is in.
  * `:game` - `nil`, or the user's current activity.
  * `:guild_id` - The ID of the guild.
  * `:status` - Either `"idle"`, `"dnd"`, `"online"` or `"offline"`.
  * `:activities` - A list of the user's current `Wumpex.Resource.Activity`.
  * `:client_status` - User's platform dependent `Wumpex.Resource.ClientStatus`.
  * `:premium_since` - When the user started boosting the guild.
  * `:nick` - This user's guild nickname (if one is set).
  """
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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.PresenceUpdate.to_struct(%{})
      %Wumpex.Resource.PresenceUpdate{}
  """
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

    struct(__MODULE__, data)
  end
end
