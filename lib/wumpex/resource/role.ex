defmodule Wumpex.Resource.Role do
  @moduledoc """
  > Roles represent a set of permissions attached to a group of users. Roles have unique names, colors, and can be "pinned" to the side bar, causing their members to be listed separately. Roles are unique per guild, and can have separate permission profiles for the global context (guild) and channel context. The @everyone role has the same ID as the guild it belongs to.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/permissions#role-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the role.
  * `:name` - The name of the role.
  * `:color` - The color of the role, represented as a hex number.
  * `:hoist` Whether this role is pinned in the user filtering.
  * `:position` - The position of the role in the UI.
  * `:permissions` - (legacy) permission bit set.
  * `:permissions_new` - Permission bit set.
  * `:managed` - Whether this role is managed by an integration.
  * `:mentionable` - Whether this role is mentionable.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          name: String.t(),
          color: non_neg_integer(),
          hoist: boolean(),
          position: non_neg_integer(),
          permissions: non_neg_integer(),
          permissions_new: String.t(),
          managed: boolean(),
          mentionable: boolean()
        }

  defstruct [
    :id,
    :name,
    :color,
    :hoist,
    :position,
    :permissions,
    :permissions_new,
    :managed,
    :mentionable
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Role.to_struct(%{})
      %Wumpex.Resource.Role{}
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
