defmodule Wumpex.Voice.Udp do
  use GenServer

  require Logger

  @type options :: [
          ip: String.t(),
          mode: String.t(),
          port: non_neg_integer(),
          ssrc: non_neg_integer(),
          controller: pid(),
          ip_discovery?: boolean()
        ]

  @type state :: %{
          socket: :gen_udp.socket(),
          remote: {:inet.ip_address(), :inet.port_number()},
          ssrc: non_neg_integer(),
          controller: pid(),
          secret_key: [non_neg_integer()] | nil
        }

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

  @impl GenServer
  @spec init(options()) :: {:ok, state()}
  def init(options) do
    ip = Keyword.fetch!(options, :ip)
    port = Keyword.fetch!(options, :port)
    ssrc = Keyword.fetch!(options, :ssrc)
    controller = Keyword.fetch!(options, :controller)
    ip_discovery? = Keyword.fetch!(options, :ip_discovery?)

    {:ok, host} = :inet.parse_address(to_charlist(ip))

    {:ok, socket} =
      :gen_udp.open(0, [
        :binary,
        {:active, true},
        {:reuseaddr, true}
      ])

    case ip_discovery? do
      true ->
        {local_ip, local_port} = ip_discovery(socket, {host, port}, ip, port, ssrc)
        Logger.debug("Finished IP discovery: #{local_ip}:#{local_port}")
        send(controller, {:ip_discovery, local_ip, local_port})

      false ->
        Logger.debug("Skipping IP discovery and returning dummy data")
        send(controller, {:ip_discovery, "127.0.0.1", 1337})
    end

    {:ok,
     %{
       socket: socket,
       remote: {host, port},
       ssrc: ssrc,
       controller: controller,
       secret_key: nil
     }}
  end

  @impl GenServer
  def handle_info({:secret_key, secret_key}, state) do
    {:noreply, %{state | secret_key: secret_key}}
  end

  # Send an IP discovery package to Discord.
  @spec ip_discovery(
          socket :: :inet.socket(),
          destination :: {:inet.ip_address(), :inet.port_number()},
          ip :: String.t(),
          port :: non_neg_integer(),
          ssrc :: non_neg_integer()
        ) :: {String.t(), non_neg_integer()}
  defp ip_discovery(socket, destination, ip, port, ssrc) do
    # As specified in https://discord.com/developers/docs/topics/voice-connections#ip-discovery
    # 2 bytes of 0x1 to indicate sending
    # 2 bytes of the message length (excluding type and length = 70)
    # 4 bytes of SSRC
    # 64 bytes <<0>> padded hostname
    # 2 bytes of unsigned port number
    discover = <<1::16, 70::16, ssrc::32>> <> String.pad_trailing(ip, 64, <<0>>) <> <<port::16>>

    send_packet(socket, destination, discover)

    receive do
      {:udp, ^socket, _ip, _port, <<2::16, 70::16, _ssrc::32, address::512, port::16>>} ->
        {String.trim(<<address::512>>, <<0>>), port}
    after
      1_000 ->
        raise "IP discovery timed out"
    end
  end

  # Sends a given packet over the UDP socket.
  defp send_packet(socket, destination, packet) do
    :gen_udp.send(socket, destination, packet)
  end
end
