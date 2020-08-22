defmodule Wumpex.Resource.Embed.Author do
  @moduledoc """
  Contains information about the author of the `Wumpex.Resource.Embed`.

  See the official [Discord dcumentation](https://discord.com/developers/docs/resources/channel#embed-object).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:name` - The name of the author.
  * `:url` - The URL of the author.
  * `:icon_url` - The URL of the author icon (only supports http(s) and attachments).
  * `:proxy_icon_url` - A proxied URL of the author icon.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t(),
          icon_url: String.t(),
          proxy_icon_url: String.t()
        }

  defstruct [
    :name,
    :url,
    :icon_url,
    :proxy_icon_url
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Author.to_struct(%{})
      %Wumpex.Resource.Embed.Author{
        name: nil,
        url: nil,
        icon_url: nil,
        proxy_icon_url: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Author.to_struct(%{"name" => "dealloc", "url" => "https://dealloc.dev"})
      %Wumpex.Resource.Embed.Author{
        name: "dealloc",
        url: "https://dealloc.dev"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
