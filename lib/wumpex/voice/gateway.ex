defmodule Wumpex.Voice.Gateway do
  use Wumpex.Base.Websocket

  alias Wumpex.Base.Websocket
  alias Wumpex.Voice.Opcodes

  require Logger

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
  * `:endpoint` - The endpoint string received from the `:VOICE_SERVER_UPDATE`.
  * `:token` - The token received from the `:VOICE_SERVER_UPDATE`.
  * `:session` - The session token received from the `:VOICE_STATE_UPDATE`.
  * `:guild_id` - The guild ID to connect to.
  * `:user_id` - The ID of the bot.
  * `:controller` - The `t:pid/0` of the controlling process (will receive the UDP information).
  """
  @type options :: [
          endpoint: String.t(),
          token: String.t(),
          session: String.t(),
          guild_id: String.t(),
          user_id: String.t(),
          controller: pid()
        ]

  @typedoc """
  Represents the process state.

  Contains the following fields:
  * `:nonce` - The last nonce sent in the heartbeats.
  """
  @type state :: %{
          nonce: non_neg_integer() | nil
        }

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    endpoint = Keyword.fetch!(options, :endpoint)
    [host, port] = String.split(endpoint, ":")

    Websocket.start_link(
      __MODULE__,
      options ++
        [
          host: host,
          port: String.to_integer(port),
          path: "/?v=4",
          timeout: :infinity
        ],
      []
    )
  end

  @doc """
  Asks the voice gateway to dispatch the SELECT PROTOCOL opcode with the given information.
  """
  @spec select_protocol(
          gateway :: pid(),
          ip :: String.t(),
          port :: non_neg_integer(),
          mode :: String.t()
        ) :: :ok
  def select_protocol(gateway, ip, port, mode) do
    GenServer.cast(gateway, {:select_protocol, ip, port, mode})

    :ok
  end

  @impl Websocket
  def on_connected(options) do
    user_id = Keyword.fetch!(options, :user_id)
    guild_id = Keyword.fetch!(options, :guild_id)
    token = Keyword.fetch!(options, :token)
    session = Keyword.fetch!(options, :session)
    controller = Keyword.fetch!(options, :controller)
    opcode = Opcodes.identify(guild_id, user_id, session, token)
    Logger.metadata(guild_id: guild_id)

    :rand.seed(:exro928ss)
    send_opcode(opcode)

    # Return state.
    %{
      nonce: nil,
      controller: controller
    }
  end

  @impl Websocket
  def handle_frame({:text, frame}, state) do
    state =
      frame
      |> Jason.decode!()
      |> dispatch(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:heartbeat, interval}, state) do
    Process.send_after(self(), {:heartbeat, interval}, interval)

    nonce = round(:rand.uniform() * 1_000_000)

    nonce
    |> Opcodes.heartbeat()
    |> send_opcode()

    {:noreply, %{state | nonce: nonce}}
  end

  @impl GenServer
  def handle_cast({:select_protocol, ip, port, mode}, state) do
    send_opcode(Opcodes.select_protocol(ip, port, mode))

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:speak, ssrc, flag}, state) do
    send_opcode(%{
      "op" => 5,
      "d" => %{
        "speaking" => flag,
        "delay" => 0,
        "ssrc" => ssrc
      }
    })

    {:noreply, state}
  end

  # Handles READY event
  defp dispatch(%{"op" => 2, "d" => event}, %{controller: controller} = state) do
    %{
      "ip" => ip,
      "modes" => modes,
      "port" => port,
      "ssrc" => ssrc
    } = event

    send(controller, {:udp_info, ip, port, modes, ssrc})

    state
  end

  # Handles HELLO event
  defp dispatch(%{"op" => 8, "d" => %{"heartbeat_interval" => interval}}, state) do
    send(self(), {:heartbeat, round(interval)})

    state
  end

  # Handles HEARTBEAT ACK event
  defp dispatch(%{"op" => 6, "d" => ack}, %{nonce: nonce} = state) do
    case ack do
      ^nonce ->
        :ok

      _nonce ->
        Logger.error("Invalid heartbeat ack received, closing connection.")
        send_frame(:close)
    end

    %{state | nonce: nil}
  end

  # Handles SESSION DESCRIPTION event
  defp dispatch(%{"op" => 4, "d" => event}, %{controller: controller} = state) do
    %{
      "audio_codec" => "opus",
      "secret_key" => secret_key
    } = event

    send(controller, {:secret_key, :erlang.list_to_binary(secret_key)})

    state
  end

  # Handles people speaking notification.
  defp dispatch(%{"op" => 5, "d" => _event}, state) do
    state
  end

  # Handles invalid opcodes
  defp dispatch(opcode, state) do
    Logger.warn("Unknown opcode received: #{inspect(opcode)}")

    state
  end

  # Send an opcode over the voice gateway.
  @spec send_opcode(opcode :: map()) :: :ok
  defp send_opcode(opcode) do
    frame = {:text, Jason.encode!(opcode)}

    send_frame(frame)
  end
end
