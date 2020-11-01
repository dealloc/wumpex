defmodule Wumpex.Voice.Connection do
  # High level abstraction over the websocket, UDP and Gateway.
  use GenServer

  alias Wumpex.Voice.AudioConnection
  alias Wumpex.Voice.GatewayMonitor
  alias Wumpex.Voice.VoiceGateway

  require Logger

  # Don't include channel because restarts.
  @type options :: [
          shard: Wumpex.shard(),
          guild: non_neg_integer()
        ]

  @type state :: %{
          ready: boolean(),
          websocket: pid() | nil,
          udp: pid() | nil,
          guild: non_neg_integer()
        }

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl GenServer
  def init(shard: shard, guild: guild) do
    Logger.metadata(guild_id: guild, shard: shard)
    GatewayMonitor.start_link(shard: shard, guild: guild, receiver: self())

    Logger.debug("Voice is booting up...")

    {:ok,
     %{
       ready: false,
       udp: nil,
       websocket: nil,
       guild: guild
     }}
  end

  @impl GenServer
  def handle_info({:server_info, voice_info}, state) do
    %{
      session: session,
      endpoint: endpoint,
      token: token
    } = voice_info

    [host, port] = String.split(endpoint, ":")

    Logger.debug("Received server info, starging Websocket connection...")

    {:ok, gateway} =
      VoiceGateway.start_link(
        host: host,
        port: String.to_integer(port),
        path: "/?v=4",
        timeout: 5_000,
        # Voice gateway specific options
        session: session,
        token: token,
        guild: state.guild,
        overseer: self()
      )

    {:noreply, %{state | websocket: gateway}}
  end

  @impl GenServer
  def handle_info({:websocket_ready, voice_info}, state) do
    Logger.debug("Received server info, starting UDP connection...")

    %{
      host: host,
      modes: modes,
      port: port,
      ssrc: ssrc
    } = voice_info

    {:ok, audio} =
      AudioConnection.start_link(
        host: host,
        modes: modes,
        port: port,
        ssrc: ssrc,
        overseer: self()
      )

    {:noreply, %{state | udp: audio}}
  end

  @impl GenServer
  def handle_info({:udp_ready, info}, %{websocket: websocket} = state) do
    Logger.debug("Received UDP information, sending SELECT PROTOCOL")
    send(websocket, {:select, info})

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:voice_ready, key}, %{udp: udp} = state) do
    Logger.debug("Sending encryption key to UDP connection")
    send(udp, {:ready, key})

    Logger.info("Voice connection is now ready to send/receive")
    {:noreply, state}
  end
end
