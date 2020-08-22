defmodule Wumpex.Resource.Embed.Thumbnail do
  @moduledoc """
  Contains thumbnail information for the `Wumpex.Resource.Embed`.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#embed-object-embed-thumbnail-structure).
  """

  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:url` - The URL of the provider.
  * `:proxy_url` - A proxied URL of the thumbnail.
  * `:height` - The height of the thumbnail.
  * `:width` - The width of the thumbnail.
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

      iex> Wumpex.Resource.Embed.Thumbnail.to_struct(%{})
      %Wumpex.Resource.Embed.Thumbnail{
        url: nil,
        proxy_url: nil,
        height: nil,
        width: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Thumbnail.to_struct(%{"url" => "url", "proxy_url" => "proxy-url", "height" => 100, "width" => 50})
      %Wumpex.Resource.Embed.Thumbnail{
        url: "url",
        proxy_url: "proxy-url",
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
