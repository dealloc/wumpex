defmodule Wumpex.Gateway.EventHandler do
  @moduledoc """
  Contains event handling logic for `Wumpex.Gateway.Worker`.

  This module contains the `dispatch/3` method which the `Wumpex.Gateway.Worker` calls after decoding an incoming message.
  Events that do not affect a specific guild directly (HELLO, READY, RESUMED, ...) are handled here.

  Events that are for a specific guild (MESSAGE_CREATE, PRESENCE_UPDATE, ...) are dispatched to the approperiate `Wumpex.Guild.Client` using the `Wumpex.Guild.Guilds` module.
  """

  alias Wumpex.Base.Websocket
  alias Wumpex.Gateway.State
  alias Wumpex.Guild.Guilds

  require Logger

  # Handles HELLO
  def dispatch(%{op: 10, d: %{heartbeat_interval: interval}}, websocket, state) do
    send(self(), {:heartbeat, interval, websocket})
    send(self(), {:identify, websocket})

    Logger.debug("Received HELLO!")
    %State{state | ack: true}
  end

  # Handles HEARTBEAT_ACK
  def dispatch(%{op: 11}, _websocket, state) do
    Logger.debug("Received heartbeat ack!")

    %State{state | ack: true}
  end

  # Handles INVALID_SESSION
  # https://discord.com/developers/docs/topics/gateway#invalid-session
  def dispatch(%{"op" => 9}, websocket, state) do
    Websocket.close(websocket, :invalid_session)

    Logger.warn("Received INVALID_SESSION, Websocket will be closed!")
    state
  end

  # Handles READY event
  def dispatch(%{op: 0, s: sequence, t: :READY, d: %{session_id: session_id}}, _websocket, state) do
    Logger.info("Bot is now READY")

    %State{state | sequence: sequence, session_id: session_id}
  end

  def dispatch(
        %{op: 0, s: sequence, t: :GUILD_CREATE, d: event},
        _websocket,
        %State{guild_sup: guild_sup} = state
      ) do
    Logger.info("Guild became available: #{inspect(event)}")

    {:ok, _guild} = Guilds.start_guild(guild_sup, event.id)

    %State{state | sequence: sequence}
  end

  def dispatch(%{op: 0, s: sequence, t: :GUILD_DELETE, d: %{id: guild_id}}, _websocket, state) do
    Logger.info("Guild #{guild_id} is no longer available!")

    Guilds.stop_guild(guild_id)

    %State{state | sequence: sequence}
  end

  def dispatch(
        %{op: 0, s: sequence, t: event_name, d: %{guild_id: guild_id} = event},
        websocket,
        state
      ) do
    Logger.debug("#{event_name} (#{guild_id}): #{inspect(event)}")

    Guilds.dispatch!(guild_id, {event_name, event, websocket})

    %State{state | sequence: sequence}
  end

  @doc """
  The dispatch event is called for all incoming events from the Discord gateway.

  The `Wumpex.Gateway.EventHandler` tries to handle any non-specific event inline, maintains the sequence state and handles resumes.
  Unknown events are simply discarded and a warning is logged.
  """
  @spec dispatch(event :: State.t(), websocket :: pid(), state :: State.t()) :: State.t()
  def dispatch(event, _websocket, state) do
    Logger.warn("Received an unhandled event: #{inspect(event)}")

    state
  end
end
