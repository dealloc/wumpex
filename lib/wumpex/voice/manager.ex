defmodule Wumpex.Voice.Manager do
  @moduledoc """
  Represents a voice connection and abstracts the `Wumpex.Voice.Gateway`,
  `Wumpex.Voice.Udp` connection and the `Wumpex.Voice.Player` process.

  This module coordinates actions that require interaction across the different processes and/or modules.
  For example, sending audio data requires sending an opcode over the voice gateway
  and then sending encrypted audio data over the UDP socket.
  """

  use GenServer, restart: :transient

  import Wumpex.Voice.VoiceServerInformation, only: [get_voice_server: 5]

  alias Wumpex.Voice.Gateway
  alias Wumpex.Voice.Player
  alias Wumpex.Voice.Udp

  require Logger

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
  * `:shard` - The shard on which to listen for the (regular) gateway events and send outgoing events.
  * `:guild` - The guild to connect to.
  * `:channel` - The (voice) channel to connect to.
  """
  @type options :: [
          shard: Wumpex.shard(),
          guild: Wumpex.guild(),
          channel: Wumpex.channel()
        ]

  @typedoc """
  Represents the process state.

  Contains the following fields:
  * `:gateway` - The `t:pid/0` of the `Wumpex.Voice.Gateway` process.
  * `:udp` - The `t:pid/0` of the `Wumpex.Voice.Udp` process.
  * `:player` - The `t:pid/0` of the `Wumpex.Voice.Player` process.
  * `:ssrc` - The [SSRC](https://webrtcglossary.com/ssrc/) for this voice connection.
  * `:shard` - The shard on which to listen for the (regular) gateway events and send outgoing events.
  * `:guild` - The guild we're connected to.
  * `:channel` - The voice channel we're connected to.
  """
  @type state :: %{
          gateway: pid(),
          udp: pid(),
          player: pid(),
          ssrc: non_neg_integer(),
          shard: Wumpex.shard(),
          guild: Wumpex.guild(),
          channel: Wumpex.channel()
        }

  @doc false
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

  @doc false
  @spec start(options()) :: GenServer.on_start()
  def start(options) do
    GenServer.start(__MODULE__, options, [])
  end

  @doc false
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
        port: port,
        ssrc: ssrc,
        controller: self(),
        ip_discovery?: false
      )

    {local_ip, local_port} = receive_ip_discovery()
    Gateway.select_protocol(gateway, local_ip, local_port, "xsalsa20_poly1305")

    secret_key = receive_secret_key()
    Logger.debug("Received secret key from voice gateway")
    {:ok, player} = Player.start_link(secret_key: secret_key, ssrc: ssrc, udp: udp)

    {:ok,
     %{
       gateway: gateway,
       udp: udp,
       player: player,
       ssrc: ssrc,
       shard: shard,
       guild: guild,
       channel: channel
     }}
  end

  @doc false
  # Handles the call to play a stream/enumerable.
  @impl GenServer
  def handle_call({:play, stream}, from, state) do
    GenServer.cast(state.gateway, {:speak, state.ssrc, [:microphone]})

    # Forward the call to the Player process, which will respond.
    send(state.player, {:"$gen_call", from, {:play, stream}})

    {:noreply, state}
  end

  @doc false
  # Handles the call to disconnect (channel is set to nil).
  @impl GenServer
  def handle_call({:connect, [channel: nil]}, _from, %{shard: shard, guild: guild} = state) do
    alias Wumpex.Gateway
    alias Wumpex.Gateway.Opcodes
    opcode = Opcodes.voice_state_update(guild, nil, [])

    shard
    |> Gateway.via()
    |> Gateway.send_opcode(opcode)

    Logger.info("Voice connection closing")
    {:stop, :normal, state}
  end

  @doc false
  # Handles the call to change the voice states, like (un)mute, (un)deafen and change channel.
  @impl GenServer
  def handle_call(
        {:connect, options},
        _from,
        %{guild: guild, channel: channel, shard: shard} = state
      ) do
    alias Wumpex.Gateway
    alias Wumpex.Gateway.Opcodes

    mute? = Keyword.get(options, :mute, false)
    deafen? = Keyword.get(options, :deafen, false)
    channel = Keyword.get(options, :channel, channel)

    opcode =
      Opcodes.voice_state_update(guild, channel,
        mute: mute?,
        deafen: deafen?
      )

    shard
    |> Gateway.via()
    |> Gateway.send_opcode(opcode)

    Logger.info("Voice state changed (mute:#{mute?} deafen?: #{deafen?} channel: #{channel})")
    {:reply, channel, %{state | channel: channel}}
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
