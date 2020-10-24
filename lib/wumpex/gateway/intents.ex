defmodule Wumpex.Gateway.Intents do
  @moduledoc """
  Contains method for representing and working with [Gateway intents](https://discord.com/developers/docs/topics/gateway#gateway-intents).
  """

  @typedoc """
  Represents all possible intents and whether or not they should be enabled.

  The full list of Discord intents can be found in the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#gateway-intents).
  """
  @type t :: %__MODULE__{
          guilds: boolean() | nil,
          guild_members: boolean() | nil,
          guild_bans: boolean() | nil,
          guild_emojis: boolean() | nil,
          guild_integrations: boolean() | nil,
          guild_webhooks: boolean() | nil,
          guild_invites: boolean() | nil,
          guild_voice_states: boolean() | nil,
          guild_presences: boolean() | nil,
          guild_messages: boolean() | nil,
          guild_message_reactions: boolean() | nil,
          guild_message_typing: boolean() | nil,
          direct_messages: boolean() | nil,
          direct_message_reactions: boolean() | nil,
          direct_message_typing: boolean() | nil
        }

  # Contains the intents and their respective bit flag.
  @intents [
    guilds: 0,
    guild_members: 1,
    guild_bans: 2,
    guild_emojis: 3,
    guild_integrations: 4,
    guild_webhooks: 5,
    guild_invites: 6,
    guild_voice_states: 7,
    guild_presences: 8,
    guild_messages: 9,
    guild_message_reactions: 10,
    guild_message_typing: 11,
    direct_messages: 12,
    direct_message_reactions: 13,
    direct_message_typing: 14
  ]

  defstruct [
    :guilds,
    :guild_members,
    :guild_bans,
    :guild_emojis,
    :guild_integrations,
    :guild_webhooks,
    :guild_invites,
    :guild_voice_states,
    :guild_presences,
    :guild_messages,
    :guild_message_reactions,
    :guild_message_typing,
    :direct_messages,
    :direct_message_reactions,
    :direct_message_typing
  ]

  @doc """
  Transforms an `Intents` struct into the numerical representation.

      iex> Wumpex.Gateway.Intents.to_integer(%Wumpex.Gateway.Intents{guilds: true})
      1
      iex> Wumpex.Gateway.Intents.to_integer(%Wumpex.Gateway.Intents{guilds: true, guild_messages: true})
      513
  """
  @spec to_integer(intents :: t()) :: non_neg_integer()
  def to_integer(%__MODULE__{} = intents) do
    use Bitwise

    intents
    |> Map.from_struct()
    |> Enum.filter(fn {_key, value} -> is_boolean(value) and value end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.reduce(0, fn intent, acc ->
      acc + (1 <<< @intents[intent])
    end)
  end

  @doc """
  Checks if this `Intents` struct contains privileged intents.
  Read more about privileged intents in the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#privileged-intents).

      iex> Wumpex.Gateway.Intents.privileged?(%Wumpex.Gateway.Intents{guilds: true})
      false
      iex> Wumpex.Gateway.Intents.privileged?(%Wumpex.Gateway.Intents{guild_members: true})
      true
  """
  @spec privileged?(intents :: t()) :: boolean()
  def privileged?(%__MODULE__{} = intents) do
    (is_boolean(intents.guild_members) and intents.guild_members) or
      (is_boolean(intents.guild_presences) and intents.guild_presences)
  end
end
