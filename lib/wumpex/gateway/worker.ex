defmodule Wumpex.Gateway.Worker do
  @moduledoc """
  Handles incoming events from the gateway.

  This module handles the raw incoming events from the gateway's `Wumpex.Base.Websocket`.
  The messages are encoded, events that are not specific to a guild, such as HELLO, IDENTIFY, INVALID_SESSION etc are handled inline.
  Events specific to a guild (MESSAGE_CREATE, ...) are passed on to the process group for that guild.
  """

  use GenServer

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(stack) do
    {:ok, stack}
  end

  @impl GenServer
  def handle_cast({{:binary, etf}, _websocket}, state) do
    {:noreply, state}
  end
end
