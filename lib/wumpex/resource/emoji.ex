defmodule Wumpex.Resource.Emoji do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Role
  alias Wumpex.Resource.User

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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = data
    |> to_atomized_map()
    |> Map.update(:roles, nil, fn roles -> to_structs(roles, Role) end)
    |> Map.update(:user, nil, &User.to_struct/1)

    struct(__MODULE__, data)
  end
end
