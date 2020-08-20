defmodule Wumpex.Resource.Activity.Party do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          id: String.t(),
          size: {non_neg_integer(), non_neg_integer()}
        }

  defstruct [
    :id,
    :size
  ]

  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:size, nil, fn [current, max] -> {current, max} end)

    struct(__MODULE__, data)
  end
end
