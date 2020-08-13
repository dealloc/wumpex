defmodule Wumpex.Resource.EmbedField do

  import Wumpex.Resource

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          inline: boolean()
        }

  defstruct [
    :name,
    :value,
    :inline
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct!(__MODULE__, data)
  end
end
