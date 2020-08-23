defmodule Wumpex.Resource.ChannelMention do
  @moduledoc """
  Represents a channel specifically mentioned in a message.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#channel-mention-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Channel

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the channel.
  * `:guild_id` - The ID of the guild containing the channel.
  * `:type` - The `t:Wumpex.Resource.Channel.channel_type/0`.
  * `:name` - The name of the channel that's mentioned.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          guild_id: Resource.snowflake(),
          type: Channel.channel_type(),
          name: String.t()
        }

  defstruct [
    :id,
    :guild_id,
    :type,
    :name
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.ChannelMention.to_struct(%{})
      %Wumpex.Resource.ChannelMention{
        id: nil,
        guild_id: nil,
        type: nil,
        name: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
