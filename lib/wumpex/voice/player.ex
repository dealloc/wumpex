defmodule Wumpex.Voice.Player do
  @moduledoc """
  The Player module is responsible for encoding and sending audio data to Discord.

  Currently only supports playing a single sound, but queueing support is planned to be added.
  """

  use GenServer

  alias Wumpex.Voice.Rtp
  alias Wumpex.Voice.Udp

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
  * `:secret_key` - The key used when encrypting outgoing packets.
  * `:ssrc` - The [SSRC](https://webrtcglossary.com/ssrc/) for this voice connection.
  * `:udp` - The `t:pid/0` of the `Wumpex.Voice.Udp` process to request a socket from.
  """
  @type options :: [
          secret_key: binary(),
          ssrc: non_neg_integer(),
          udp: pid()
        ]

  @typedoc """
  Represents the process state.

  Contains the following fields:
  * `:ssrc` - The [SSRC](https://webrtcglossary.com/ssrc/) for this voice connection.
  * `:secret_key` - The key used when encrypting outgoing packets.
  * `:socket` - The `t:Wumpex.Voice.Udp.socket/0` used for sending data.
  * `:current` - The currently being played audio data.
  * `:sequence` - The sequence used when building RTP header data.
  * `:time` - The time used when building RTP header data.
  """
  @type state :: %{
          ssrc: non_neg_integer(),
          secret_key: binary(),
          socket: Udp.socket(),
          current: Enum.t() | nil,
          sequence: non_neg_integer(),
          time: non_neg_integer()
        }

  @doc false
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

  @doc false
  @impl GenServer
  @spec init(options()) :: {:ok, state()}
  def init(options) do
    ssrc = Keyword.fetch!(options, :ssrc)
    secret_key = Keyword.fetch!(options, :secret_key)
    udp = Keyword.fetch!(options, :udp)
    socket = GenServer.call(udp, :socket)

    {:ok,
     %{
       ssrc: ssrc,
       secret_key: secret_key,
       socket: socket,
       current: nil,
       sequence: 0,
       time: 0
     }}
  end

  @doc false
  # Handles calls to queue/play a new audio stream.
  @impl GenServer
  def handle_call({:play, stream}, _from, state) do
    key = make_ref()

    send(self(), {:play, key})
    {:reply, key, %{state | current: stream}}
  end

  # Play audio fragment and queue the next audio fragment.
  @impl GenServer
  def handle_info({:play, key}, %{current: stream} = state) do
    [frame] = Enum.take(stream, 1)
    stream = Enum.drop(stream, 1)

    packet = Rtp.encode(frame, state.sequence, state.time, state.ssrc, state.secret_key)
    Udp.send_packet(state.socket, packet)

    unless Enum.empty?(stream) do
      Process.send_after(self(), {:play, key}, 20)
    end

    {:noreply, %{state | sequence: state.sequence + 1, time: state.time + 960, current: stream}}
  end
end
