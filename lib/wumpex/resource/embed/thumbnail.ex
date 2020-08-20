defmodule Wumpex.Resource.Embed.Thumbnail do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          url: String.t(),
          proxy_url: String.t(),
          height: non_neg_integer(),
          width: non_neg_integer()
        }

  defstruct [
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
