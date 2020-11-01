defmodule Wumpex.Voice.GatewayMonitor do
  use GenServer, restart: :transient

  alias Wumpex.Api.Ratelimit
  alias Wumpex.Gateway

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl GenServer
  def init(shard: shard, guild: guild, receiver: receiver) do
    Gateway.subscribe(shard)

    # TODO: we should get this information from cache rather than fetch it every time.
    {:ok,
     %{
       body: %{
         "id" => bot_id
       }
     }} = Ratelimit.request({:get, "/users/@me", "", [], []}, {:user, :me})

    {:ok,
     %{guild: guild, id: String.to_integer(bot_id), session: nil, token: nil, endpoint: nil, receiver: receiver}}
  end

  @impl GenServer
  def handle_info(
        {:event,
         %{
           name: :VOICE_STATE_UPDATE,
           payload: %{guild_id: guild_id, session_id: session, user_id: user_id}
         }},
        %{guild: guild, id: id} = state
      )
      when guild_id == guild and user_id == id do
    check_if_ready(%{state | session: session})
  end

  @impl GenServer
  def handle_info(
        {:event,
         %{
           name: :VOICE_SERVER_UPDATE,
           payload: %{guild_id: guild_id, endpoint: endpoint, token: token}
         }},
        %{guild: guild} = state
      )
      when guild_id == guild do
    check_if_ready(%{state | endpoint: endpoint, token: token})
  end

  @impl GenServer
  def handle_info({:event, _event}, state), do: {:noreply, state}

  defp check_if_ready(state) do
    with %{session: session} when is_binary(session) <- state,
         %{endpoint: endpoint} when is_binary(endpoint) <- state,
         %{token: token} when is_binary(token) <- state do
      dispatch_voice_information(state)
      {:stop, :normal, state}
    else
      _state -> {:noreply, state}
    end
  end

  defp dispatch_voice_information(state) do
    voice_info = Map.take(state, [:session, :endpoint, :token])

    send(state.receiver, {:server_info, voice_info})
    :ok
  end
end
