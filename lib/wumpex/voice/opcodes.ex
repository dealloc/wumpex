defmodule Wumpex.Voice.Opcodes do
  @moduledoc """
  Provides methods for generating opcodes.

  See the [official documentation](https://discord.com/developers/docs/topics/opcodes-and-status-codes#voice.
  """

  @typedoc """
  Represents a generic OPCODE response.

  Opcodes usually have a top level `"op"` field which contains the numerical ID and a `"d"` field which contains the payload.
  """
  @type opcode :: map()

  @doc """
  Generates an IDENTIFY opcode.

      iex> Wumpex.Voice.Opcodes.identify("server", "user", "session", "token")
      %{"op" => 0, "d" => %{"server_id" => "server", "user_id" => "user", "session_id" => "session", "token" => "token"}}

  See the [official documentation](https://discord.com/developers/docs/topics/voice-connections#establishing-a-voice-websocket-connection-example-voice-identify-payload).
  """
  @spec identify(
          server :: String.t(),
          user :: String.t(),
          session :: String.t(),
          token :: String.t()
        ) :: opcode()
  def identify(server, user, session, token),
    do: %{
      "op" => 0,
      "d" => %{
        "server_id" => server,
        "user_id" => user,
        "session_id" => session,
        "token" => token
      }
    }

  @doc """
  Generates a HEARTBEAT opcode.

      iex> Wumpex.Voice.Opcodes.heartbeat(nil)
      %{"op" => 3, "d" => nil}

      iex> Wumpex.Voice.Opcodes.heartbeat(100)
      %{"op" => 3, "d" => 100}

  See the [official documentation](https://discord.com/developers/docs/topics/voice-connections#heartbeating-example-heartbeat-payload).
  """
  @spec heartbeat(nonce :: String.t() | non_neg_integer()) :: opcode()
  def heartbeat(nonce),
    do: %{
      "op" => 3,
      "d" => nonce
    }

  @doc """
  generates a SELECT PROTOCOL opcode.

      iex> Wumpex.Voice.Opcodes.select_protocol("ip", 123, "mode")
      %{"op" => 1, "d" => %{"protocol" => "udp", "data" => %{"address" => "ip", "port" => 123, "mode" => "mode"}}}
  """
  @spec select_protocol(ip :: String.t(), port :: non_neg_integer(), mode :: String.t()) ::
          opcode()
  def select_protocol(ip, port, mode),
    do: %{
      "op" => 1,
      "d" => %{
        "protocol" => "udp",
        "data" => %{
          "address" => ip,
          "port" => port,
          "mode" => mode
        }
      }
    }
end
