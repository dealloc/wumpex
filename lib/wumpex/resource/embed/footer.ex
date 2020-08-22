defmodule Wumpex.Resource.Embed.Footer do
  @moduledoc """
  Contains information about the footer of the `Wumpex.Resource.Embed`.

  Check the official [Discord documentation](https://discord.com/developers/docs/resources/channel#embed-object-embed-footer-structure).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:text` - The footer text
  * `:icon_url` The URL of the footer icon (only supports http(s) and attachments).
  * `:proxy_icon_url` A proxied of the footer icon.
  """
  @type t :: %__MODULE__{
          text: String.t(),
          icon_url: String.t(),
          proxy_icon_url: String.t()
        }

  defstruct [
    :text,
    :icon_url,
    :proxy_icon_url
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Footer.to_struct(%{})
      %Wumpex.Resource.Embed.Footer{
        text: nil,
        icon_url: nil,
        proxy_icon_url: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Footer.to_struct(%{"text" => "footer", "icon_url" => "url"})
      %Wumpex.Resource.Embed.Footer{
        text: "footer",
        icon_url: "url",
        proxy_icon_url: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
