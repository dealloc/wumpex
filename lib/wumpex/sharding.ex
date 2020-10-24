defmodule Wumpex.Sharding do
  @moduledoc """
  Manages the shards connected to the gateway.

  This module will retrieve the required information from the Discord API and start shards accordingly.
  """

  use GenServer

  alias HTTPoison.Response
  alias Wumpex.Api
  alias Wumpex.Gateway.Intents

  require Logger

  @typedoc """
  Represents the state of the Sharding process.

  Contains the following fields:
  * `:url` - The URL of the Discord gateway to connect to.
  * `:concurrency` - How many shards can be started concurrently.
  """
  @type state :: %{
          url: String.t(),
          concurrency: non_neg_integer()
        }

  @spec start_link(options :: keyword()) :: Supervisor.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  def init(_options) do
    %{
      url: url,
      shard_count: shards,
      concurrency: concurrency
    } = get_sharding()

    for i <- 0..(shards - 1) do
      if i != 0 and rem(i, concurrency) == 0 do
        Logger.info("Waiting 5s before starting next shards...")
        Process.sleep(5_000)
      end

      send(self(), {:start_shard, {i, shards}})
    end

    {:ok,
     %{
       url: url,
       concurrency: concurrency
     }}
  end

  @impl GenServer
  @spec handle_info({:start_shard, Wumpex.shard()}, state()) :: {:noreply, state()}
  def handle_info({:start_shard, shard}, state) do
    DynamicSupervisor.start_child(Wumpex.ShardSupervisor, {Wumpex.Gateway,
     [
       # Websocket options.
       host: state.url,
       port: 443,
       path: "/?v=8&encoding=etf",
       timeout: 5_000,
       # Gateway specific options.
       shard: shard,
       token: Wumpex.token(),
       intents: %Intents{
        guilds: true,
        guild_members: true,
        guild_bans: true,
        guild_emojis: true,
        guild_integrations: true,
        guild_webhooks: true,
        guild_invites: true,
        guild_voice_states: true,
        guild_presences: true,
        guild_messages: true,
        guild_message_reactions: true,
        guild_message_typing: true,
        direct_messages: true,
        direct_message_reactions: true,
        direct_message_typing: true
       }
     ]})

    {:noreply, state}
  end

  # Get the sharding information from the Discord API.
  defp get_sharding do
    %Response{
      status_code: status_code,
      body: body
    } = Api.get!("/gateway/bot")

    case status_code do
      200 ->
        get_sharding(body)

      _status ->
        raise """
        Failed to retrieve Discord sharding information, received status #{status_code}!
        Response: #{inspect(body)}
        """
    end
  end

  # Fetch the sharding information from the payload.
  defp get_sharding(%{
         "url" => "wss://" <> url,
         "shards" => shards,
         "session_start_limit" => %{
           "max_concurrency" => concurrency,
           "remaining" => remaining,
           "reset_after" => reset_after
         }
       }) do
    if shards > remaining do
      raise """
      Could not start all required shards (#{shards}) because Discord allows starting #{remaining} anymore.
      Please wait #{reset_after}ms before attempting to restart.
      """
    end

    %{
      url: url,
      shard_count: shards,
      concurrency: concurrency
    }
  end
end
