defmodule Wumpex.Resource.Message.Activity do
  @moduledoc """
  Sent with Rich Presence-related chat embeds.
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:type` - The `t:activity_type/0`.
  * `:party_id` - The `party_id` from a [rich presence event](https://discord.com/developers/docs/rich-presence/how-to#updating-presence-update-presence-payload-fields).
  """
  @type t :: %__MODULE__{
          type: activity_type(),
          party_id: String.t()
        }

  @typedoc """
  The type of activity.

  Can have the following values:
  * `1` - JOIN
  * `2` - SPECTATE
  * `3` - LISTEN
  * `5` - JOIN_REQUEST
  """
  @type activity_type :: 1 | 2 | 3 | 5

  defstruct [
    :type,
    :party_id
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Message.Activity.to_struct(%{})
      %Wumpex.Resource.Message.Activity{
        type: nil,
        party_id: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Message.Activity.to_struct(%{"type" => 1, "party_id" => "123"})
      %Wumpex.Resource.Message.Activity{
        type: 1,
        party_id: "123"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
