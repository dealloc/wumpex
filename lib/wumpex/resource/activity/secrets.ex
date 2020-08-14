defmodule Wumpex.Resource.Activity.Secrets do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          join: String.t(),
          spectate: String.t(),
          match: String.t()
        }

  defstruct [
    :join,
    :spectate,
    :match
  ]

  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct!(__MODULE__, data)
  end
end
