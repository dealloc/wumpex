defmodule Wumpex.Resource.Activity.Timestamps do
  import Wumpex.Resource

  @type t :: %__MODULE__{
          start: DateTime.t(),
          end: DateTime.t()
        }

  defstruct [
    :start,
    :end
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:start, nil, &to_datetime/1)
      |> Map.update(:end, nil, &to_datetime/1)

    struct!(__MODULE__, data)
  end
end
