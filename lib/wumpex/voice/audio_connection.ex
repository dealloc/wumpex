defmodule Wumpex.Voice.AudioConnection do
  use GenServer

  require Logger

  @type options :: [
          host: String.t(),
          modes: [String.t()],
          port: pos_integer(),
          ssrc: term(),
          overseer: pid()
        ]

  @type state :: %{
          socket: port(),
          discord_ip: :inet.ip_address(),
          discord_port: :inet.port_number(),
          ssrc: term(),
          modes: [String.t()],
          overseer: pid(),
          secret: binary()
        }

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl GenServer
  def init(options) do
    host = Keyword.fetch!(options, :host)
    modes = Keyword.fetch!(options, :modes)
    port = Keyword.fetch!(options, :port)
    ssrc = Keyword.fetch!(options, :ssrc)
    overseer = Keyword.fetch!(options, :overseer)

    {:ok, ip} = :inet.parse_address(to_charlist(host))

    {:ok, socket} =
      :gen_udp.open(0, [
        :binary,
        {:active, true},
        {:reuseaddr, true}
      ])

    # As specified in https://discord.com/developers/docs/topics/voice-connections#ip-discovery
    # 2 bytes of 0x1 to indicate sending
    # 2 bytes of the message length (excluding type and length = 70)
    # 4 bytes of SSRC
    # 64 bytes <<0>> padded hostname
    # 2 bytes of unsigned port number
    discover = <<1::16, 70::16, ssrc::32>> <> String.pad_trailing(host, 64, <<0>>) <> <<port::16>>

    Logger.debug("Starting IP discovery to #{host}...")
    :gen_udp.send(socket, ip, port, discover)

    {:ok,
     %{
       socket: socket,
       discord_ip: ip,
       discord_port: port,
       ssrc: ssrc,
       modes: modes,
       overseer: overseer,
       secret: []
     }}
  end

  def handle_info({:ready, key}, state) do
    Logger.debug("Received encryption key")

    {:noreply, %{state | secret: :erlang.list_to_binary(key)}}
  end

  @impl GenServer
  def handle_info(
        {:udp, _socket, _ip, _port, <<2::16, 70::16, _ssrc::32, address::512, port::16>>},
        %{overseer: overseer} = state
      ) do
    ip = String.trim(<<address::512>>, <<0>>)

    send(
      overseer,
      {:udp_ready,
       %{
         address: ip,
         port: port,
         mode: "xsalsa20_poly1305"
       }}
    )

    Logger.debug("Finished IP discovery")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, _ip, _port, _frame}, state) do
    {:noreply, state}
  end
end
