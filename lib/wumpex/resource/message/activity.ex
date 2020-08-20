defmodule Wumpex.Resource.Message.Activity do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          type: non_neg_integer(),
          party_id: String.t()
        }

  defstruct [
    :type,
    :party_id
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
