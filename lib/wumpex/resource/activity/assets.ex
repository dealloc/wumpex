defmodule Wumpex.Resource.Activity.Assets do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          large_image: String.t(),
          large_text: String.t(),
          small_image: String.t(),
          small_text: String.t()
        }

  defstruct [
    :large_image,
    :large_text,
    :small_image,
    :small_text
  ]

  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
