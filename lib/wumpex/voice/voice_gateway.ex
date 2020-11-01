defmodule Wumpex.Voice.VoiceGateway do
  use Wumpex.Base.Websocket

  alias Wumpex.Api.Ratelimit
  alias Wumpex.Base.Websocket

  @type options :: [
          session: String.t(),
          token: String.t(),
          guild: non_neg_integer(),
          overseer: pid()
        ]

  @type state :: %{
          overseer: pid(),
          nonce: non_neg_integer(),
          session: String.t(),
          token: String.t(),
          guild: non_neg_integer(),
          user_id: non_neg_integer(),
          ssrc: term()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(options) do
    Websocket.start_link(__MODULE__, options)
  end

  # Send an opcode over the voice gateway.
  @spec send_opcode(opcode :: map()) :: :ok
  defp send_opcode(opcode) do
    frame = {:text, Jason.encode!(opcode)}

    send_frame(frame)
  end

  @impl Websocket
  @spec on_connected(options()) :: state()
  def on_connected(options) do
    :rand.seed(:exro928ss)
    overseer = Keyword.fetch!(options, :overseer)
    session = Keyword.fetch!(options, :session)
    token = Keyword.fetch!(options, :token)
    guild = Keyword.fetch!(options, :guild)
    {:ok,
     %{
       body: %{
         "id" => bot_id
       }
     }} = Ratelimit.request({:get, "/users/@me", "", [], []}, {:user, :me})

    send(self(), :identify)
    %{
      overseer: overseer,
      nonce: 0,
      session: session,
      token: token,
      guild: guild,
      user_id: bot_id,
      ssrc: nil
    }
  end

  @impl Websocket
  @spec handle_frame(Websocket.frame(), state()) :: {:noreply, state()}
  def handle_frame({:text, json}, state) do
    state =
      json
      |> Jason.decode!()
      |> dispatch(state)

    {:noreply, state}
  end

  @impl Websocket
  def handle_frame({:binary, etf}, state) do
    state =
      etf
      |> :erlang.binary_to_term()
      |> dispatch(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:heartbeat, interval}, state) do
    nonce = round(:rand.uniform() * 1_000_000)
    send_opcode(%{
      "op" => 3,
      "d" => nonce
    })

    Logger.debug("Heartbeat #{nonce}")
    Process.send_after(self(), {:heartbeat, interval}, interval)
    {:noreply, %{state | nonce: nonce}}
  end

  @impl GenServer
  def handle_info(:identify, %{guild: guild, session: session, token: token, user_id: user_id} = state) do
    send_opcode(%{
      "op" => 0,
      "d" => %{
        "server_id" => guild,
        "user_id" => user_id,
        "session_id" => session,
        "token" => token
      }
    })

    Logger.debug("Sending IDENTIFY to voice gateway")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:select, %{address: host, port: port, mode: mode}}, state) do
    send_opcode(%{
      "op" => 1,
      "d" => %{
        "protocol" => "udp",
        "data" => %{
          "address" => host,
          "port" => port,
          "mode" => mode
        }
      }
    })

    Logger.debug("Sending SELECT PROTOCOL to voice gateway")
    {:noreply, state}
  end

  # Handles HELLO
  @spec dispatch(map(), state()) :: state()
  defp dispatch(%{"op" => 8, "d" => %{"heartbeat_interval" => interval}}, state) do
    send(self(), {:heartbeat, round(interval) - 100})

    state
  end

  # Handles HEARTBEAT ACK
  defp dispatch(%{"op" => 6, "d" => nonce}, state) do
    Logger.debug("Ack #{nonce}")

    state
  end

  # Handles READY
  defp dispatch(%{"op" => 2, "d" => %{"ip" => ip, "modes" => modes, "port" => port, "ssrc" => ssrc}}, %{overseer: overseer} = state) do
    send(overseer, {:websocket_ready, %{
      host: ip,
      modes: modes,
      port: port,
      ssrc: ssrc
    }})

    Logger.info("Voice gateway is now READY")
    %{state | ssrc: ssrc}
  end

  defp dispatch(%{"op" => 4, "d" => %{"secret_key" => key}}, %{overseer: overseer} = state) do
    send(overseer, {:voice_ready, key})

    Logger.debug("Received SESSION DESCRIPTION from voice gateway")
    state
  end

  defp dispatch(event, state) do
    Logger.warn("Unknown event #{inspect(event)}")

    state
  end
end
