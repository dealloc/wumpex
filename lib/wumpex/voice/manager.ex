defmodule Wumpex.Voice.Manager do
  @moduledoc """
  Represents a voice connection and abstracts the voice gateway and UDP connection.
  """

  use GenServer

  import Wumpex.Voice.VoiceServerInformation, only: [get_voice_server: 5]

  alias Wumpex.Voice.Gateway
  alias Wumpex.Voice.Player
  alias Wumpex.Voice.Udp

  require Logger

  @type options :: [
          shard: Wumpex.shard(),
          guild: String.t(),
          channel: String.t()
        ]

  @type state :: %{
          gateway: pid(),
          udp: pid(),
          player: pid(),
          ssrc: non_neg_integer()
        }

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

  @impl GenServer
  @spec init(options()) :: {:ok, state()}
  def init(options) do
    shard = Keyword.fetch!(options, :shard)
    guild = Keyword.fetch!(options, :guild)
    channel = Keyword.fetch!(options, :channel)
    user_id = Wumpex.user_id()

    Logger.metadata(shard: shard)

    %{
      endpoint: endpoint,
      guild_id: ^guild,
      token: token,
      session: session
    } = get_voice_server(shard, guild, channel, user_id, 6_000)

    {:ok, gateway} =
      Gateway.start_link(
        endpoint: endpoint,
        token: token,
        guild_id: guild,
        session: session,
        user_id: user_id,
        controller: self()
      )

    {ip, port, _modes, ssrc} = receive_udp()
    Logger.debug("Received UDP connection details")

    {:ok, udp} =
      Udp.start_link(
        ip: ip,
        mode: "xsalsa20_poly1305",
        port: port,
        ssrc: ssrc,
        controller: self(),
        ip_discovery?: false
      )

    {local_ip, local_port} = receive_ip_discovery()
    Gateway.select_protocol(gateway, local_ip, local_port, "xsalsa20_poly1305")

    secret_key = receive_secret_key()
    Logger.info("Received secret key from voice gateway")
    {:ok, player} = Player.start_link(secret_key: secret_key, ssrc: ssrc, udp: udp)

    {:ok,
     %{
       gateway: gateway,
       udp: udp,
       player: player,
       ssrc: ssrc
     }}
  end

  @impl GenServer
  def handle_call({:play, stream}, from, state) do
    GenServer.cast(state.gateway, {:speak, state.ssrc, 5})

    # Forward the call to the Player process, which will respond.
    send(state.player, {:"$gen_call", from, {:play, stream}})

    {:noreply, state}
  end

  # Receives the UDP information that's being sent from the voice gateway's READY handler.
  @spec receive_udp() ::
          {ip :: String.t(), port :: non_neg_integer(), modes :: [String.t()],
           ssrc :: non_neg_integer()}
  defp receive_udp do
    receive do
      {:udp_info, ip, port, modes, ssrc} ->
        {ip, port, modes, ssrc}
    after
      5_000 ->
        raise "Did not receive UDP information from voice gateway."
    end
  end

  # Receives the IP discovery from the UDP connection.
  @spec receive_ip_discovery() :: {String.t(), :inet.port_number()}
  defp receive_ip_discovery do
    receive do
      {:ip_discovery, local_ip, local_port} ->
        {local_ip, local_port}
    after
      5_000 ->
        raise "Did not receive IP discovery from UDP connection."
    end
  end

  # Receives the secret key from the voice gateway.
  @spec receive_secret_key() :: binary()
  defp receive_secret_key do
    receive do
      {:secret_key, secret_key} ->
        secret_key
    after
      5_000 ->
        raise "Did not receive secret key from voice gateway."
    end
  end
end
