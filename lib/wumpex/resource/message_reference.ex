defmodule Wumpex.Resource.MessageReference do
  import Wumpex.Resource

  alias Wumpex.Resource

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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
      data = to_atomized_map(data)

      struct!(__MODULE__, data)
  end
end
