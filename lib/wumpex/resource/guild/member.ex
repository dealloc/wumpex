defmodule Wumpex.Resource.Guild.Member do
  @moduledoc """
  Represents a member of a guild.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/guild#guild-member-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.User

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:user` - The user this guild member represents.
  * `:nick` - This user's guild nickname.
  * `:roles` - A list of role object ids.
  * `:joined_at` - A `DateTime` of when the user joined the guild.
  * `:premium_since` - When the user started boosting the guild.
  * `:deaf` - Whether the user is deafened in voice channels.
  * `:mute` - Whether the user is muted in voice channels.
  """
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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Guild.Member.to_struct(%{})
      %Wumpex.Resource.Guild.Member{
        user: nil,
        nick: nil,
        roles: nil,
        joined_at: nil,
        premium_since: nil,
        deaf: nil,
        mute: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Guild.Member.to_struct(%{"nick" => "dealloc"})
      %Wumpex.Resource.Guild.Member{
        user: nil,
        nick: "dealloc",
        roles: nil,
        joined_at: nil,
        premium_since: nil,
        deaf: nil,
        mute: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:user, nil, &User.to_struct/1)
      |> Map.update(:joined_at, nil, &Resource.to_datetime/1)
      |> Map.update(:premium_since, nil, &Resource.to_datetime/1)

    struct(__MODULE__, data)
  end
end
