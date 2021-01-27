defmodule Wumpex.Voice.Player do
  @moduledoc """
  The Player module is responsible for encoding and sending audio data to Discord.

  Currently only supports playing a single sound, but queueing support is planned to be added.
  """

  use GenServer

  alias Wumpex.Voice.Rtp
  alias Wumpex.Voice.Udp

  require Logger

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
  * `:queue` - A list of all the audio fragments that are waiting to be played.
  """
  @type state :: %{
          ssrc: non_neg_integer(),
          secret_key: binary(),
          socket: Udp.socket(),
          current: reference() | nil,
          sequence: non_neg_integer(),
          time: non_neg_integer(),
          queue: [{reference(), Enum.t()}]
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
       time: 0,
       queue: []
     }}
  end

  @doc false
  # Handles calls to queue/play a new audio stream.
  @impl GenServer
  def handle_call({:play, stream}, _from, %{queue: []} = state) do
    key = make_ref()
    queue = [{key, stream}]

    Logger.info("Begin playing #{inspect(key)}")
    send(self(), {:play, key})
    {:reply, key, %{state | current: key, queue: queue}}
  end

  @doc false
  # Handles calls to queue/play a new audio stream.
  @impl GenServer
  def handle_call({:play, stream}, _from, %{queue: queue} = state) do
    key = make_ref()
    queue = queue ++ [{key, stream}]

    Logger.info("Queued #{inspect(key)}, #{Enum.count(queue) - 1} items before it.")
    {:reply, key, %{state | queue: queue}}
  end

  # Play audio fragment and queue the next audio fragment.
  @impl GenServer
  def handle_info({:play, key}, %{current: current, queue: queue} = state) when key == current do
    [{^key, stream} | queue] = queue
    {frame, new_stream} = pop_frame(stream)

    packet = Rtp.encode(frame, state.sequence, state.time, state.ssrc, state.secret_key)
    Udp.send_packet(state.socket, packet)

    {new_current, new_queue} =
      if Enum.empty?(new_stream) do
        send_silence(state.socket)

        Logger.info("Finished playing #{inspect(key)}")
        get_next_item(queue)
      else
        Process.send_after(self(), {:play, key}, 20)

        {key, [{key, new_stream}] ++ queue}
      end

    {:noreply,
     %{
       state
       | sequence: state.sequence + 1,
         time: state.time + 960,
         queue: new_queue,
         current: new_current
     }}
  end

  @spec send_silence(Udp.socket()) :: :ok
  defp send_silence(socket) do
    for _i <- 1..5 do
      Udp.send_packet(socket, Rtp.silence())
    end

    :ok
  end

  # Pop the frame from the stream (uses Enum to support all Enumerable types).
  @spec pop_frame(Enum.t()) :: {binary(), Enum.t()}
  defp pop_frame(stream) do
    [frame] = Enum.take(stream, 1)

    {frame, Enum.drop(stream, 1)}
  end

  @spec get_next_item(queue :: list()) :: {reference() | nil, list()}
  defp get_next_item(queue) do
    case Enum.take(queue, 1) do
      [] ->
        Logger.info("Finished playing all items in queue")
        {nil, []}

      [{key, _stream}] ->
        Logger.info("Begin playing #{inspect(key)}")
        Process.send_after(self(), {:play, key}, 20)
        {key, queue}
    end
  end
end
