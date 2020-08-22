defmodule Wumpex.Resource.Activity.Timestamps do
  @moduledoc """
  Unix timestamps for start and/or end of the game.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#activity-object).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:start` - `DateTime` of when the activity started.
  * `:end` - `DateTime` of when the activity ends.
  """
  @type t :: %__MODULE__{
          start: DateTime.t(),
          end: DateTime.t()
        }

  defstruct [
    :start,
    :end
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Timestamps.to_struct(%{})
      %Wumpex.Resource.Activity.Timestamps{
        start: nil,
        end: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Timestamps.to_struct(%{"start" => 1598091581660, "end" => 1598091604956})
      %Wumpex.Resource.Activity.Timestamps{
        start: ~U[2020-08-22 10:19:41.660Z],
        end: ~U[2020-08-22 10:20:04.956Z]
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:start, nil, &to_datetime/1)
      |> Map.update(:end, nil, &to_datetime/1)

    struct(__MODULE__, data)
  end
end
