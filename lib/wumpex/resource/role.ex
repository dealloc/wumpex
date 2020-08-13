defmodule Wumpex.Resource.Role do
  @moduledoc """
  > Roles represent a set of permissions attached to a group of users. Roles have unique names, colors, and can be "pinned" to the side bar, causing their members to be listed separately. Roles are unique per guild, and can have separate permission profiles for the global context (guild) and channel context. The @everyone role has the same ID as the guild it belongs to.
  """

  import Wumpex.Resource

  alias Wumpex.Resource

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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct!(__MODULE__, data)
  end
end
