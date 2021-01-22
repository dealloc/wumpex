defmodule Wumpex.Voice.Player do
  use GenServer

  @type options :: [
          secret_key: binary(),
          ssrc: non_neg_integer(),
          udp: pid()
        ]

  @type state :: %{
          ssrc: non_neg_integer(),
          secret_key: binary(),
          send_fn: function()
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
    send_fn = GenServer.call(udp, :socket)

    {:ok,
     %{
       ssrc: ssrc,
       secret_key: secret_key,
       send_fn: send_fn
     }}
  end

  @impl GenServer
  def handle_call({:play, _stream}, _from, state) do
    {:reply, make_ref(), state}
  end
end
