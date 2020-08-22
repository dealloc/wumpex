defmodule Wumpex.Resource.Embed.Video do
  @moduledoc """
  Contains video information for the `Wumpex.Resource.Embed`.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#embed-object-embed-video-structure).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:url` - The URL of the provider.
  * `:height` - The height of the video.
  * `:width` - The width of the video.
  """
  @type t :: %__MODULE__{
          url: String.t(),
          height: non_neg_integer(),
          width: non_neg_integer()
        }

  defstruct [
    :url,
    :height,
    :width
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Video.to_struct(%{})
      %Wumpex.Resource.Embed.Video{
        url: nil,
        height: nil,
        width: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Video.to_struct(%{"url" => "url", "height" => 100, "width" => 50})
      %Wumpex.Resource.Embed.Video{
        url: "url",
        height: 100,
        width: 50
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
