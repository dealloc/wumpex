defmodule Wumpex.Voice.Player do
  use GenServer

  alias Wumpex.Voice.RTP
  alias Wumpex.Voice.Udp

  @type options :: [
          secret_key: binary(),
          ssrc: non_neg_integer(),
          udp: pid()
        ]

  @type state :: %{
          ssrc: non_neg_integer(),
          secret_key: binary(),
          socket: Udp.socket(),
          current: Enum.t() | nil,
          sequence: non_neg_integer(),
          time: non_neg_integer()
        }

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

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

  @impl GenServer
  def handle_call({:play, stream}, _from, state) do
    key = make_ref()

    send(self(), {:play, key})
    {:reply, key, %{state | current: stream}}
  end

  # Play audio fragment.
  @impl GenServer
  def handle_info({:play, key}, %{current: stream} = state) do
    [frame] = Enum.take(stream, 1)
    stream = Enum.drop(stream, 1)

    packet = RTP.encode(frame, state.sequence, state.time, state.ssrc, state.secret_key)
    Udp.send_packet(state.socket, packet)
    unless Enum.empty?(stream) do
      Process.send_after(self(), {:play, key}, 20)
    end
    {:noreply, %{state | sequence: state.sequence + 1, time: state.time + 960, current: stream}}
  end
end
