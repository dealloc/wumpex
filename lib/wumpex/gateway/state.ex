defmodule Wumpex.Gateway.State do
  @moduledoc """
  Represents the state of `Wumpex.Gateway.Worker`.

  See `t:t/0`.
  """

  @typedoc """
  The state of the `Wumpex.Gateway.Worker` module.
    * `:token` - The [bot token](https://discord.com/developers/docs/reference#authentication) to authenticate against Discord.
    * `:ack` - Whether or not a heartbeat ACK has been received.
    * `:sequence` - The ID of the last received event.
    * `:session_id` - Session token, can be used to resume an interrupted session.
    * `:guild_sup` - The `Wumpex.Guild.Guilds` supervisor.
  """
  @type t :: %__MODULE__{
          token: String.t(),
          ack: boolean(),
          sequence: non_neg_integer() | nil,
          session_id: String.t() | nil,
          guild_sup: pid()
        }

  @enforce_keys [:token, :ack]

  defstruct [:token, :ack, :sequence, :session_id, :guild_sup]
end
