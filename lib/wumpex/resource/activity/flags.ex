defmodule Wumpex.Resource.Activity.Flags do
  use Bitwise

  @type t :: %__MODULE__{
          instance: boolean(),
          join: boolean(),
          spectate: boolean(),
          join_request: boolean(),
          sync: boolean(),
          play: boolean()
        }

  defstruct [
    :instance,
    :join,
    :spectate,
    :join_request,
    :sync,
    :play
  ]

  @spec to_struct(data :: non_neg_integer()) :: t()
  def to_struct(data) when is_number(data) do
    %__MODULE__{
      instance: (data &&& 1 <<< 0) == 1 <<< 0,
      join: (data &&& 1 <<< 1) == 1 <<< 1,
      spectate: (data &&& 1 <<< 2) == 1 <<< 2,
      join_request: (data &&& 1 <<< 3) == 1 <<< 3,
      sync: (data &&& 1 <<< 4) == 1 <<< 4,
      play: (data &&& 1 <<< 5) == 1 <<< 5
    }
  end
end
