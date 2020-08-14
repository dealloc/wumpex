defmodule Wumpex.Resource.Activity.Emoji do
  import Wumpex.Resource

  alias Wumpex.Resource

  @type t :: %__MODULE__{
          name: String.t(),
          id: Resource.snowflake(),
          animated: boolean()
        }

  defstruct [
    :name,
    :id,
    :animated
  ]

  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct!(__MODULE__, data)
  end
end
