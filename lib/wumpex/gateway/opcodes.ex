defmodule Wumpex.Gateway.Opcodes do
  @moduledoc """
  Provides methods for generating opcodes.

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#commands-and-events-gateway-commands) for a full list.
  """

  @typedoc """
  Represents a generic OPCODE response.

  Opcodes usually have a top level `"op"` field which contains the numerical ID and a `"d"` field which contains the payload.
  """
  @type opcode :: map()

  @doc """
  Generates a HEARTBEAT opcode.

      iex> Wumpex.Gateway.Opcodes.heartbeat(nil)
      %{"op" => 1, "d" => nil}

      iex> Wumpex.Gateway.Opcodes.heartbeat(100)
      %{"op" => 1, "d" => 100}

  See the [official documentation](https://discord.com/developers/docs/topics/gateway#heartbeat).
  """
  @spec heartbeat(sequence :: non_neg_integer() | nil) :: opcode()
  def heartbeat(sequence) when is_nil(sequence) or is_integer(sequence),
    do: %{
      "op" => 1,
      "d" => sequence
    }

  @doc """
  Generate an IDENTIFY opcode.

      iex> Wumpex.Gateway.Opcodes.identify("test")
      %{
        "op" => 2,
        "d" => %{
          "token" => "test",
          "properties" => %{
            "$os" => :linux,
            "$browser" => "wumpex",
            "$device" => "wumpex"
          }
        }
      }

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

      iex> Wumpex.Gateway.Opcodes.resume("test", 20, "session")
      %{
        "op" => 6,
        "d" => %{
          "token" => "test",
          "session_id" => "session",
          "seq" => 20
        }
      }

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
