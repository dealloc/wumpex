defmodule Wumpex.Gateway.EventHandler do
  alias Wumpex.Gateway.State
  alias Wumpex.Base.Websocket

  require Logger

  # Handles HELLO
  def dispatch(%{op: 10, d: %{heartbeat_interval: interval}}, websocket, state) do
    send(self(), {:heartbeat, interval, websocket})
    send(self(), {:identify, websocket})

    %State{state | ack: true}
  end

  # Handles HEARTBEAT_ACK
  def dispatch(%{op: 11}, _websocket, state), do: %State{state | ack: true}

  # Handles INVALID_SESSION
  # https://discord.com/developers/docs/topics/gateway#invalid-session
  def dispatch(%{"op" => 9}, websocket, state) do
    Websocket.close(websocket, :invalid_session)

    state
  end

  # Handles READY event
  def dispatch(%{op: 0, s: sequence, t: :READY, d: %{session_id: session_id}}, _websocket, state) do
    Logger.info("Bot is now READY")

    %State{state | sequence: sequence, session_id: session_id}
  end

  def dispatch(%{op: 0, s: sequence, t: :GUILD_CREATE, d: event}, _websocket, state) do
    Logger.info("Guild became available: #{inspect(event)}")

    # TODO we should start up a guild worker here.

    %State{state | sequence: sequence}
  end

  def dispatch(%{op: 0, s: sequence, t: :GUILD_DELETE, d: %{id: guild_id}}, _websocket, state) do
    Logger.info("Guild #{guild_id} is no longer available!")

    # TODO we should start up a guild worker here.

    %State{state | sequence: sequence}
  end

  def dispatch(%{op: 0, s: sequence, t: event_name, d: %{guild_id: guild_id} = event}, _websocket, state) do
    Logger.info("#{event_name} (#{guild_id}): #{inspect(event)}")

    # TODO we should dispatch to the relevant guild worker here

    %State{state | sequence: sequence}
  end

  @spec dispatch(event :: State.t(), websocket :: pid(), state :: State.t()) :: State.t()
  def dispatch(event, _websocket, state) do
    Logger.warn("Received an unhandled event: #{inspect(event)}")

    state
  end
end
