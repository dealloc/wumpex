defmodule Wumpex.Resource.EmbedProvider do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t()
        }

  defstruct [
    :name,
    :url
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct!(__MODULE__, data)
  end
end
