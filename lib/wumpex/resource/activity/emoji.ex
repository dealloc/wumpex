defmodule Wumpex.Resource.Activity.Emoji do
  @moduledoc """
  The emoji used for a custom status
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:name` - the name of the emoji.
  * `:id` - the id of the emoji.
  * `:animated` - whether this emoji is animated.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          id: Resource.snowflake(),
          animated: boolean()
        }

  defstruct [
    :name,
    :id,
    :animated
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Emoji.to_struct(%{})
      %Wumpex.Resource.Activity.Emoji{
        name: nil,
        id: nil,
        animated: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Emoji.to_struct(%{"name" => "emoji-name"})
      %Wumpex.Resource.Activity.Emoji{
        name: "emoji-name"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
