defmodule Wumpex.Resource.Activity.Party do
  @moduledoc """
  Information for the current party of the player.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#activity-object-activity-party).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - the id of the party
  * `:size` - used to show the party's current and maximum size
  """
  @type t :: %__MODULE__{
          id: String.t(),
          size: {non_neg_integer(), non_neg_integer()}
        }

  defstruct [
    :id,
    :size
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Party.to_struct(%{})
      %Wumpex.Resource.Activity.Party{
        id: nil,
        size: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Party.to_struct(%{"id" => "snowflake", "size" => [0, 0]})
      %Wumpex.Resource.Activity.Party{
        id: "snowflake",
        size: {0, 0}
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:size, nil, fn [current, max] -> {current, max} end)

    struct(__MODULE__, data)
  end
end
