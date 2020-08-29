defmodule Wumpex.Resource.Embed.Image do
  @moduledoc """
  Contains image information of an embed.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#embed-object-embed-image-structure).
  """

  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:url` - The source URL of image (only supports http(s) and attachments).
  * `:proxy_url` - A proxied URL of the image.
  * `:height` - The height of the image.
  * `:width` - The width of the image.
  """
  @type t :: %__MODULE__{
          url: String.t(),
          proxy_url: String.t(),
          height: non_neg_integer(),
          width: non_neg_integer()
        }

  defstruct [
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Image.to_struct(%{})
      %Wumpex.Resource.Embed.Image{
        url: nil,
        proxy_url: nil,
        height: nil,
        width: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Image.to_struct(%{"url" => "url", "width" => 0, "height" => 0})
      %Wumpex.Resource.Embed.Image{
        url: "url",
        proxy_url: nil,
        width: 0,
        height: 0
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
