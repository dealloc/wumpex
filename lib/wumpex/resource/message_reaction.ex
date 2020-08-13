defmodule Wumpex.Resource.MessageReaction do
  import Wumpex.Resource

  alias Wumpex.Resource.Emoji

  @type t :: %__MODULE__{
    count: non_neg_integer(),
    me: boolean(),
    emoji: Emoji.t()
  }

  defstruct [
    :count,
    :me,
    :emoji
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = data
    |> to_atomized_map()
    |> Map.update(:emoji, nil, &Emoji.to_struct/1)

    struct!(__MODULE__, data)
  end
end
