defmodule Wumpex.Gateway.Opcodes do
  @moduledoc """
  Provides methods for generating opcodes.

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#commands-and-events-gateway-commands) for a full list.
  """

  @type opcode :: map()

  @doc """
  Generates a HEARTBEAT opcode.

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#heartbeat).
  """
  @spec heartbeat(sequence :: non_neg_integer() | nil) :: opcode()
  def heartbeat(sequence),
    do: %{
      "op" => 1,
      "d" => sequence
    }

  @doc """
  Generate an IDENTIFY opcode.

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#identify)
  """
  @spec identify(token :: String.t()) :: opcode()
  def identify(token) do
    {_, os} = :os.type()

    %{
      "op" => 2,
      "d" => %{
        "token" => token,
        # "intents" => 512,
        "properties" => %{
          "$os" => os,
          "$browser" => "wumpex",
          "$device" => "wumpex"
        }
      }
    }
  end

  @doc """
  Generate a RESUME opcode.

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#resume)
  """
  @spec resume(token :: String.t(), sequence :: non_neg_integer(), session_id :: String.t()) ::
          opcode()
  def resume(token, sequence, session_id),
    do: %{
      "op" => 6,
      "d" => %{
        "token" => token,
        "session_id" => session_id,
        "seq" => sequence
      }
    }
end
