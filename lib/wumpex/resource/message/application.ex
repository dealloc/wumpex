defmodule Wumpex.Resource.Message.Application do
  @moduledoc """
  Application information sent with Rich presence related embeds.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#message-object-message-application-structure).
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the application
  * `:cover_image` - The ID of the embed's image asset.
  * `:description` - The description of the application.
  * `:icon` - The ID of the application's icon.
  * `:name` - The name of the application.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          cover_image: String.t(),
          description: String.t(),
          icon: String.t(),
          name: String.t()
        }

  defstruct [
    :id,
    :cover_image,
    :description,
    :icon,
    :name
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Message.Application.to_struct(%{})
      %Wumpex.Resource.Message.Application{
        id: nil,
        cover_image: nil,
        description: nil,
        icon: nil,
        name: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Message.Application.to_struct(%{"id" => "snowflake"})
      %Wumpex.Resource.Message.Application{
        id: "snowflake",
        cover_image: nil,
        description: nil,
        icon: nil,
        name: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
