defmodule Wumpex.Gateway do
  @moduledoc """
  Handles incoming events from the gateway.

  This module handles the raw incoming events from the gateway's `Wumpex.Base.Websocket`.
  The messages are decoded, events that are not specific to a guild, such as HELLO, IDENTIFY, INVALID_SESSION etc are handled inline.
  Events specific to a guild (MESSAGE_CREATE, ...) are passed on to the process group for that guild.
  """

  use Wumpex.Base.Websocket

  alias Wumpex.Base.Websocket
  alias Wumpex.Gateway.Caching
  alias Wumpex.Gateway.Consumers
  alias Wumpex.Gateway.Event
  alias Wumpex.Gateway.EventProducer
  alias Wumpex.Gateway.Intents
  alias Wumpex.Gateway.Opcodes

  require Logger

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
    * `:token` - The bot token
    * `:shard` - the identifier for this shard.
    * `:intents` - The `t:Wumpex.Gateway.Intents.t/0` struct containing intent information.
    * `:handlers` - The handlers for this gateway's events.
  """
  @type options :: [
          token: String.t(),
          shard: Wumpex.shard(),
          intents: Intents.t(),
          handlers: [Consumers.handler_options()]
        ]

  @typedoc """
  The state of the `Wumpex.Gateway.Worker` module.

    * `:token` - The [bot token](https://discord.com/developers/docs/reference#authentication) to authenticate against Discord.
    * `:ack` - Whether or not a heartbeat ACK has been received.
    * `:sequence` - The ID of the last received event.
    * `:session_id` - Session token, can be used to resume an interrupted session.
    * `:shard` - the identifier for this shard.
    * `:intents` - The intents information (calculated from `Wumpex.Gateway.Intents.to_integer/1`).
  """
  @type state :: %{
          token: String.t(),
          ack: boolean(),
          sequence: non_neg_integer() | nil,
          session_id: String.t() | nil,
          shard: Wumpex.shard(),
          intents: non_neg_integer()
        }

  @doc false
  @spec start_link(options :: options()) :: GenServer.on_start()
  def start_link(options) do
    shard = Keyword.fetch!(options, :shard)

    Websocket.start_link(__MODULE__, options, name: via(shard))
  end

  @doc """
  Subscribes the current process to events from the given gateway.

  Events will be sent in the form of `{:event, %Wumpex.Gateway.Event{}}`.
  """
  @spec subscribe(Wumpex.shard()) :: :ok
  def subscribe(shard), do: subscribe(shard, self())

  @doc """
  Subscribes the given processes to events from the given gateway.

  Events will be sent in the form of `{:event, %Wumpex.Gateway.Event{}}`.
  """
  @spec subscribe(Wumpex.shard(), pid_or_pids :: pid() | [pid()]) :: :ok
  def subscribe(shard, pid_or_pids) do
    group = "wumpex:shard:#{inspect(shard)}"

    :pg.join(:wumpex, group, pid_or_pids)
  end

  @doc """
  Unsubscribes the current process of events from the given gateway.
  """
  @spec unsubscribe(Wumpex.shard()) :: :ok | :not_joined
  def unsubscribe(shard), do: unsubscribe(shard, self())

  @doc """
  Unsubscribes the given processes of events from the given gateway.
  """
  @spec unsubscribe(Wumpex.shard(), pid_or_pids :: pid() | [pid()]) :: :ok | :not_joined
  def unsubscribe(shard, pid_or_pids) do
    group = "wumpex:shard:#{inspect(shard)}"

    :pg.leave(:wumpex, group, pid_or_pids)
  end

  @doc """
  Gets the server name of the `Wumpex.Gateway` process for a given shard.
  You can use this to get the `pid` of the gateway, or to send opcodes to it.

      # The shard (represented as a tuple).
      {0, 1}
      # Get the server name.
      |> Wumpex.Gateway.via()
      # Dispatch an opcode to it.
      |> Wumpex.Gateway.send_opcode(%{"op" => 1})
  """
  @spec via(shard :: Wumpex.shard()) :: GenServer.server()
  def via(shard), do: {:via, Wumpex.Sharding.ShardLedger, "gateway:" <> inspect(shard)}

  @doc """
  Dispatches an event on the gateway.

  This method will handle rate limiting, encoding of the message etc.
  Note that there's *no* validation on what's being sent, so be careful invoking this method.

  Invalid messages will cause Discord to close the gateway.
  """
  @spec send_opcode(gateway :: GenServer.server(), opcode :: map()) :: :ok
  def send_opcode(gateway, opcode) when is_map(opcode) do
    pid = GenServer.whereis(gateway)
    encoded = :erlang.term_to_binary(opcode)

    Websocket.send(pid, {:binary, encoded})
  end

  # Private version of send_opcode/2 which sends directly to the gateway.
  @spec send_opcode(opcode :: map()) :: :ok
  defp send_opcode(opcode) when is_map(opcode) do
    encoded = :erlang.term_to_binary(opcode)

    send_frame({:binary, encoded})
  end

  # Broadcasts an event to all listeners for this shard.
  @spec broadcast(Event.t(), Wumpex.shard()) :: :ok
  defp broadcast(event, shard) do
    group = "wumpex:shard:#{inspect(shard)}"
    listeners = :pg.get_members(:wumpex, group)

    Manifold.send(listeners, {:event, event})
  end

  @impl Websocket
  def on_connected(options) do
    token = Keyword.fetch!(options, :token)
    shard = Keyword.fetch!(options, :shard)
    intents = Keyword.fetch!(options, :intents)
    handlers = Keyword.fetch!(options, :handlers)
    {:ok, producer} = EventProducer.start_link(shard: shard)
    {:ok, caching} = Caching.start_link(producer: producer)

    for handler <- handlers do
      {:ok, _consumer} = Consumers.start_consumer(caching, handler)
    end

    Logger.metadata(shard: inspect(shard))
    Logger.debug("Connected to the gateway!")

    %{
      token: token,
      ack: false,
      sequence: nil,
      session_id: nil,
      shard: shard,
      intents: Intents.to_integer(intents)
    }
  end

  @impl Websocket
  def on_disconnected(state) do
    Logger.warn("Disconnected from gateway!")

    :telemetry.execute([:wumpex, :gateway, :disconnect], %{
      timestamp: :os.system_time(:millisecond),
      retry_after: 1_000
    })

    {{:retry, 1_000}, state}
  end

  @impl Websocket
  def on_reconnected(state) do
    Logger.info("Reconnected!")

    :telemetry.execute([:wumpex, :gateway, :reconnect], %{
      timestamp: :os.system_time(:millisecond)
    })

    state
  end

  @impl Websocket
  def handle_frame({:binary, etf}, state) do
    state =
      :telemetry.span([:wumpex, :gateway, :dispatch], %{}, fn ->
        result =
          etf
          |> :erlang.binary_to_term()
          |> dispatch(state)

        {result, %{}}
      end)

    {:noreply, state}
  end

  # Handles incoming requests to send out an IDENTIFY
  @impl GenServer
  def handle_info(
        :identify,
        %{
          token: token,
          sequence: sequence,
          session_id: session_id,
          shard: shard,
          intents: intents
        } = state
      ) do
    identify_or_resume =
      case session_id do
        nil ->
          Logger.info("Sending IDENTIFY")
          Opcodes.identify(token, shard, intents)

        session_id ->
          Logger.warn("Sending RESUME")
          Opcodes.resume(token, sequence, session_id)
      end

    send_opcode(identify_or_resume)
    {:noreply, state}
  end

  # Handles heartbeats
  @impl GenServer
  def handle_info({:heartbeat, interval}, %{sequence: sequence, ack: true} = state) do
    hearbeat = Opcodes.heartbeat(sequence)
    send_opcode(hearbeat)

    Logger.info("Sent heartbeat #{sequence}")
    Process.send_after(self(), {:heartbeat, interval}, interval)
    {:noreply, %{state | ack: false}}
  end

  # Got a heartbeat without receiving an ACK for the previous heartbeat.
  # According to the docs, we need to close the connection and resume.
  @impl GenServer
  def handle_info({:heartbeat, _interval}, state) do
    Logger.warn("No heartbeat ack was received between heartbeats!")
    send_frame(:close)

    {:noreply, %{state | ack: false}}
  end

  # Handles HELLO
  # https://discord.com/developers/docs/topics/gateway#hello
  def dispatch(%{op: 10, d: %{heartbeat_interval: interval}}, state) do
    send(self(), {:heartbeat, interval})
    send(self(), :identify)

    Logger.debug("Received HELLO!")
    %{state | ack: true}
  end

  # Handles HEARTBEAT_ACK
  # https://discord.com/developers/docs/topics/gateway#heartbeating
  def dispatch(%{op: 11}, state) do
    Logger.debug("Received heartbeat ack!")

    %{state | ack: true}
  end

  # Handles INVALID_SESSION
  # https://discord.com/developers/docs/topics/gateway#invalid-session
  def dispatch(%{op: 9, d: resumable}, state) do
    Logger.warn("Received INVALID_SESSION, Websocket will be closed!")
    send_frame(:close)

    # Check if we can resume, otherwise clear session data.
    if resumable do
      state
    else
      %{state | session_id: nil, ack: false, sequence: nil}
    end
  end

  # Handles RECONNECT
  # https://discord.com/developers/docs/topics/opcodes-and-status-codes#opcodes-and-status-codes
  def dispatch(%{op: 7}, state) do
    send_frame(:close)

    state
  end

  # Handles READY event
  # https://discord.com/developers/docs/topics/gateway#ready
  def dispatch(
        %{op: 0, s: sequence, t: :READY, d: %{session_id: session_id} = event},
        state
      ) do
    Logger.info("Bot is now READY #{inspect(event)}")

    # Ready, we received initial guilds and user information.
    broadcast(
      %Event{
        shard: state.shard,
        name: :READY,
        payload: event,
        sequence: sequence
      },
      state.shard
    )

    %{state | sequence: sequence, session_id: session_id}
  end

  # Handles RESUMED event
  # https://discord.com/developers/docs/topics/gateway#resumed
  def dispatch(%{op: 0, s: sequence, t: :RESUMED}, state) do
    Logger.info("Bot has finished resuming.")

    broadcast(
      %Event{
        shard: state.shard,
        name: :RESUMED,
        payload: %{},
        sequence: sequence
      },
      state.shard
    )

    %{state | sequence: sequence}
  end

  # Forwards events to the processing stages.
  def dispatch(%{op: 0, s: sequence, t: event_name, d: event}, state) do
    broadcast(
      %Event{
        shard: state.shard,
        name: event_name,
        payload: event,
        sequence: sequence
      },
      state.shard
    )

    %{state | sequence: sequence}
  end

  @doc """
  The dispatch event is called for all incoming events from the Discord gateway.

  The `Wumpex.Gateway.Worker` tries to handle any non-specific event inline, maintains the sequence state and handles resumes.
  Unknown events are simply discarded and a warning is logged.
  """
  @spec dispatch(event :: state(), state :: state()) :: state()
  def dispatch(event, state) do
    Logger.warn("Received an unhandled event: #{inspect(event)}")

    state
  end

  @spec format_status(:normal | :terminate, [pdict :: {term(), term()} | (state :: term()), ...]) ::
          term()
  def format_status(options, [dict, state]) do
    [data: data] = super(options, [dict, state])

    [
      data:
        data ++
          [
            Shard: state.shard,
            Sequence: state.sequence,
            "Heartbeat Ack'd": state.ack
          ]
    ]
  end
end
