defmodule Wumpex.Resource.Attachment do
  import Wumpex.Resource

  alias Wumpex.Resource

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          filename: String.t(),
          size: non_neg_integer(),
          url: String.t(),
          height: non_neg_integer(),
          width: non_neg_integer()
        }

  defstruct [
    :id,
    :filename,
    :size,
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct!(__MODULE__, data)
  end
end
