defmodule Wumpex.Gateway do
  @moduledoc """
  Provides helper methods for interacting with the Discord gateway.
  """

  alias Wumpex.Base.Websocket

  @doc """
  Dispatches an event on the gateway.

  This method will handle rate limiting, encoding of the message etc.
  Note that there's *no* validation on what's being sent, so be careful invoking this method.

  Invalid messages will cause Discord to close the gateway.
  """
  @spec dispatch(gateway :: pid(), opcode :: map()) :: :ok
  def dispatch(gateway, opcode) when is_pid(gateway) and is_map(opcode) do
    encoded = :erlang.term_to_binary(opcode)

    Websocket.send(gateway, {:binary, encoded})
  end
end
