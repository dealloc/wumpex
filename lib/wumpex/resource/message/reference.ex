defmodule Wumpex.Resource.Message.Reference do
  @moduledoc """
  Reference data sent with crossposted messages.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#message-object-message-reference-structure).
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:message_id` - The ID of the originating message.
  * `:channel_id` - The ID of the originating message's channel.
  * `:guild_id` - The ID of the originating message's guild.
  """
  @type t :: %__MODULE__{
          message_id: Resource.snowflake(),
          channel_id: Resource.snowflake(),
          guild_id: Resource.snowflake()
        }

  defstruct [
    :message_id,
    :channel_id,
    :guild_id
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Message.Reference.to_struct(%{})
      %Wumpex.Resource.Message.Reference{
        message_id: nil,
        channel_id: nil,
        guild_id: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Message.Reference.to_struct(%{"message_id" => "snowflake"})
      %Wumpex.Resource.Message.Reference{
        message_id: "snowflake"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
