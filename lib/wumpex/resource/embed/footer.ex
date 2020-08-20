defmodule Wumpex.Resource.Embed.Footer do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          text: String.t(),
          icon_url: String.t(),
          proxy_icon_url: String.t()
        }

  defstruct [
    :text,
    :icon_url,
    :proxy_icon_url
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
