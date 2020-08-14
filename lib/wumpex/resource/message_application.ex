defmodule Wumpex.Resource.MessageApplication do
  import Wumpex.Resource

  alias Wumpex.Resource

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          cover_image: String.t(),
          description: String.t(),
          icon: String.t(),
          name: String.t()
        }

  defstruct [
    :id,
    :cover_image,
    :description,
    :icon,
    :name
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct!(__MODULE__, data)
  end
end
