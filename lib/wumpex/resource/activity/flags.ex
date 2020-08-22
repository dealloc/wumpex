defmodule Wumpex.Resource.Activity.Flags do
  @moduledoc """
  [activity flags](https://discord.com/developers/docs/topics/gateway#activity-object-activity-flags) **OR**d together, describes what the payload includes
  """

  use Bitwise

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:instance` - true if this flag was passed along.
  * `:join` - true if this flag was passed along.
  * `:spectate` - true if this flag was passed along.
  * `:join_request` - true if this flag was passed along.
  * `:sync` - true if this flag was passed along.
  * `:play` - true if this flag was passed along.
  """
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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Flags.to_struct(1)
      %Wumpex.Resource.Activity.Flags{
        instance: true,
        join: false,
        spectate: false,
        join_request: false,
        sync: false,
        play: false
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Flags.to_struct(8)
      %Wumpex.Resource.Activity.Flags{
        instance: false,
        join: false,
        spectate: false,
        join_request: true,
        sync: false,
        play: false
      }
  """
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
