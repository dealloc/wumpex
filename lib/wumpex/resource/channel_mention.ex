defmodule Wumpex.Resource.ChannelMention do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Channel

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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
