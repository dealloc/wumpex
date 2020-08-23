defmodule Wumpex.Resource.Attachment do
  @moduledoc """
  Represents a file attached to a message.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#attachment-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The attachment ID.
  * `:filename` - The name of the file attached.
  * `:size` - The size of the file in bytes.
  * `:url` - The URL of the file.
  * `:proxy_url` - A proxied URL of the file.
  * `:height` - The height of file (if an image).
  * `:width` - The width of file (if an image).
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          filename: String.t(),
          size: non_neg_integer(),
          url: String.t(),
          height: non_neg_integer(),
          width: non_neg_integer()
        }

  defstruct [
    :id,
    :filename,
    :size,
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Attachment.to_struct(%{})
      %Wumpex.Resource.Attachment{
        id: nil,
        filename: nil,
        size: nil,
        url: nil,
        proxy_url: nil,
        height: nil,
        width: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Attachment.to_struct(%{"id" => "id", "filename" => "file-name"})
      %Wumpex.Resource.Attachment{
        id: "id",
        filename: "file-name",
        size: nil,
        url: nil,
        proxy_url: nil,
        height: nil,
        width: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
