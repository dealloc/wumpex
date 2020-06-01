defmodule Wumpex.Gateway.Worker do
  @moduledoc """
  Handles incoming events from the gateway.

  This module handles the raw incoming events from the gateway's `Wumpex.Base.Websocket`.
  The messages are encoded, events that are not specific to a guild, such as HELLO, IDENTIFY, INVALID_SESSION etc are handled inline.
  Events specific to a guild (MESSAGE_CREATE, ...) are passed on to the process group for that guild.
  """

  use GenServer

  import Wumpex.Gateway.EventHandler

  alias Wumpex.Gateway
  alias Wumpex.Gateway.Opcodes
  alias Wumpex.Gateway.State

  require Logger

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
    * `:token` - The bot token
    * `:shard` - the identifier for this shard, in the form of `{current_shard, shard_count}`
    * `:gateway` - The URL this shard should connect to.
    * `:guild_sup` - The `Wumpex.Guild.Guilds` supervisor.
  """
  @type options :: [
          token: String.t(),
          shard: {non_neg_integer(), non_neg_integer()},
          gateway: String.t(),
          guild_sup: pid()
        ]

  @spec start_link(options :: options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl GenServer
  @spec init(options :: options()) :: {:ok, State.t()}
  def init(options) do
    token = Keyword.fetch!(options, :token)
    guild_sup = Keyword.fetch!(options, :guild_sup)
    shard = Keyword.fetch!(options, :shard)

    Logger.metadata(shard: inspect(shard))
    {:ok,
     %State{
       token: token,
       ack: false,
       guild_sup: guild_sup
     }}
  end

  @impl GenServer
  def handle_cast({{:binary, etf}, websocket}, state) do
    state =
      etf
      |> :erlang.binary_to_term()
      |> dispatch(websocket, state)

    {:noreply, state}
  end

  # Handles incoming requests to send out an IDENTIFY
  @impl GenServer
  def handle_info(
        {:identify, websocket},
        %State{token: token, sequence: sequence, session_id: session_id} = state
      ) do
    message =
      case session_id do
        nil ->
          Logger.info("Sending IDENTIFY")
          Opcodes.identify(token)

        session_id ->
          Logger.info("Sending RESUME")
          Opcodes.resume(token, sequence, session_id)
      end

    Gateway.dispatch(websocket, message)
    {:noreply, state}
  end

  # Handles heartbeats
  @impl GenServer
  def handle_info(
        {:heartbeat, interval, websocket},
        %State{sequence: sequence, ack: true} = state
      ) do
    message = Opcodes.heartbeat(sequence)
    Gateway.dispatch(websocket, message)

    Logger.info("Sent heartbeat ##{sequence}")
    Process.send_after(self(), {:heartbeat, interval, websocket}, interval)
    {:noreply, %State{state | ack: false}}
  end

  # Got a heartbeat without receiving an ACK for the previous heartbeat.
  # According to the docs, we need to close the connection and resume.
  @impl GenServer
  def handle_info({:heartbeat, _interval, _websocket}, state) do
    Logger.warn("No heartbeat ack was received between heartbeats!")

    {:noreply, %State{state | ack: false}}
  end
end
