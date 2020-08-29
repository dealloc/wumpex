defmodule Wumpex.Resource.Guild.ChannelFlags do
  @moduledoc """
  Represents system channel flags for a guild.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags).
  """

  use Bitwise

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:suppress_join_notifications` - Whether a message will be shown in the system channel when a new user joins.
  * `:suppress_premium_subscriptions` - Whether a message will be shown in the system channel when a user boosts the server.
  """
  @type t :: %__MODULE__{
          suppress_join_notifications: boolean(),
          suppress_premium_subscriptions: boolean()
        }

  defstruct [
    :suppress_join_notifications,
    :suppress_premium_subscriptions
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Guild.ChannelFlags.to_struct(0)
      %Wumpex.Resource.Guild.ChannelFlags{
        suppress_join_notifications: false,
        suppress_premium_subscriptions: false
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Guild.ChannelFlags.to_struct(1)
      %Wumpex.Resource.Guild.ChannelFlags{
        suppress_join_notifications: true,
        suppress_premium_subscriptions: false
      }
  """
  @spec to_struct(data :: non_neg_integer()) :: t()
  def to_struct(data) when is_number(data) do
    %__MODULE__{
      suppress_join_notifications: (data &&& 1 <<< 0) == 1 <<< 0,
      suppress_premium_subscriptions: (data &&& 1 <<< 1) == 1 <<< 1
    }
  end
end
