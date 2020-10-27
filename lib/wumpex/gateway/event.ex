defmodule Wumpex.Gateway.Event do
  @moduledoc """
  Represents a single event dispatched from the `Wumpex.Gateway`.
  """

  @typedoc """
  Represents an event that will be dispatched from the gateway to consumers.

  Contains the following fields:
  * `:shard` - A `t:Wumpex.shard/0` representing the shard from which the event originates.
  * `:name` - An atom with the name of the dispatched event.
  * `:payload` - The event payload in the form of a map.
  * `:sequence` - The sequence number of the event, can be used to track the same event across handlers.
  """
  @type t :: %__MODULE__{
          shard: Wumpex.shard(),
          name: atom(),
          payload: map(),
          sequence: pos_integer()
        }

  @enforce_keys [:shard, :name, :payload, :sequence]

  defstruct [
    :shard,
    :name,
    :payload,
    :sequence
  ]

  @doc """
  Get the guild ID of a given event.

  If the given event is not for a specific guild, this function will return nil.
  """
  @spec guild(t()) :: pos_integer() | nil
  def guild(%__MODULE__{name: name, payload: payload}) when is_map(payload) do
    case name do
      :GUILD_CREATE ->
        Map.get(payload, :id, nil)

      _name ->
        Map.get_lazy(payload, :guild_id, fn ->
          Map.get(payload, "guild_id")
        end)
    end
  end
end
