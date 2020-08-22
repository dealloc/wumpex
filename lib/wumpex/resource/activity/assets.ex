defmodule Wumpex.Resource.Activity.Assets do
  @moduledoc """
  Images for the presence and their hover texts.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#activity-object-activity-assets).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:large_image` - the id for a large asset of the activity, usually a `t:Wumpex.Resource.snowflake/0`.
  * `:large_text` - text displayed when hovering over the large image of the activity.
  * `:small_image` - the id for a small asset of the activity, usually a `t:Wumpex.Resource.snowflake/0`.
  * `:small_text`  - text displayed when hovering over the small image of the activity.
  """
  @type t :: %__MODULE__{
          large_image: String.t(),
          large_text: String.t(),
          small_image: String.t(),
          small_text: String.t()
        }

  defstruct [
    :large_image,
    :large_text,
    :small_image,
    :small_text
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Assets.to_struct(%{})
      %Wumpex.Resource.Activity.Assets{
        large_image: nil,
        large_text: nil,
        small_image: nil,
        small_text: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Assets.to_struct(%{"large_image" => "snowflake-here"})
      %Wumpex.Resource.Activity.Assets{
        large_image: "snowflake-here"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
