defmodule Wumpex.Resource.Emoji do
  @moduledoc """
  Represent an emoji that can be sent.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/emoji).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Role
  alias Wumpex.Resource.User

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The emoji ID.
  * `:name` The name of the emoji.
  * `:roles` - The roles this emoji is whitelisted to.
  * `:user` - The user that created this emoji.
  * `:require_colons` - Whether this emoji must be wrapped in colons.
  * `:managed` - Whether this emoji is managed.
  * `:animated` - Whether this emoji is animated.
  * `:available` - Whether this emoji can be used, may be false due to the loss of server boosts.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          name: String.t(),
          roles: [Role.t()],
          user: User.t(),
          require_colons: boolean(),
          managed: boolean(),
          animated: boolean(),
          available: boolean()
        }

  defstruct [
    :id,
    :name,
    :roles,
    :user,
    :require_colons,
    :managed,
    :animated,
    :available
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Emoji.to_struct(%{})
      %Wumpex.Resource.Emoji{
        id: nil,
        name: nil,
        roles: nil,
        user: nil,
        require_colons: nil,
        managed: nil,
        animated: nil,
        available: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:user, nil, &User.to_struct/1)

    struct(__MODULE__, data)
  end
end
