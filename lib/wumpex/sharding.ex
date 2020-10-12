defmodule Wumpex.Sharding do
  @moduledoc """
  Manages the shards connected to the gateway.

  This module will retrieve the required information from the Discord API and start shards accordingly.
  """

  use Supervisor

  alias Wumpex.Api
  alias Wumpex.Sharding.ShardLedger

  require Logger

  @spec start_link(options :: keyword()) :: Supervisor.on_start()
  def start_link(options) do
    case Application.get_env(:wumpex, :connect, true) do
      false ->
        :ignore

      true ->
        Supervisor.start_link(__MODULE__, options, name: __MODULE__)
    end
  end

  @impl Supervisor
  def init(_options) do
    ShardLedger.start_link()

    Supervisor.init(get_shards(),
      strategy: :one_for_one,
      max_restarts: 0
    )
  end

  # Build a list of child_spec for each shard that needs to be started.
  @spec get_shards() :: [Supervisor.child_spec()]
  defp get_shards do
    %{
      body: %{
        "url" => "wss://" <> url,
        "shards" => shard_count
      }
    } = Api.get!("/gateway/bot")

    Logger.debug("Generating #{shard_count} shard(s) to #{url}")

    for i <- 0..(shard_count - 1) do
      {Wumpex.Gateway,
       [
         # Websocket options.
         host: url,
         port: 443,
         path: "/?v=8&encoding=etf",
         timeout: 5_000,
         # Gateway specific options.
         shard: {i, shard_count},
         token: Wumpex.token()
       ]}
    end
  end
end
