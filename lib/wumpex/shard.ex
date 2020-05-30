defmodule Wumpex.Shard do
  @moduledoc """
  Provides a single instance of a [shard](https://discord.com/developers/docs/topics/gateway#sharding).

  > As bots grow and are added to an increasing number of guilds, some developers may find it necessary to break or split portions of their bots operations into separate logical processes.
  > As such, Discord gateways implement a method of user-controlled guild sharding which allows for splitting events across a number of gateway connections.
  > Guild sharding is entirely user controlled, and requires no state-sharing between separate connections to operate.

  Sharding is a way for bots to route traffic to multiple instances (on the same node, or distributed).
  The `Wumpex.Shard` module represents a single instance of such a shard, meaning it's a routed instance to which events for guilds and voice connections are sent.

  Discord uses the [following formula](https://discord.com/developers/docs/topics/gateway#sharding-sharding-formula) to route traffic across shards:
      (guild_id >> 22) % num_shards == shard_id

  Direct messages will always arrive on shard `0`.

  If your bot is in more than 250K guilds, check out [Sharding for Very Large Bots](https://discord.com/developers/docs/topics/gateway#sharding-for-very-large-bots)
  """

  use GenServer

  require Logger

  @typedoc """
  The options that can be passed into `start_link/1` and `init/1`.

  Contains the following fields:
    * `:shard` - the identifier for this shard, in the form of `[current_shard, shard_count]`
  """
  @type options :: [
    shard: {non_neg_integer(), non_neg_integer()},
    gateway: String.t()
  ]

  @typedoc """
  The state of the shard.

  Contains the following fields:
    * `:supervisor` - the `DynamicSupervisor` that supervises the children of the shard.
  """
  @type state :: %{
    supervisor: pid()
  }

  @spec start_link(options :: options()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl GenServer
  def init(options) do
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, %{
      supervisor: supervisor
    }, {:continue, options}}
  end

  # Finish up the initialization.
  @impl GenServer
  def handle_continue(options, %{supervisor: supervisor} = state) do
    shard = Keyword.fetch!(options, :shard)
    gateway = Keyword.fetch!(options, :gateway)

    {:ok, worker} = DynamicSupervisor.start_child(supervisor, {Wumpex.Gateway.Worker, shard: shard})
    {:ok, _websocket} = DynamicSupervisor.start_child(supervisor, {Wumpex.Base.Websocket, url: "#{gateway}?v=6&encoding=etf", worker: worker})

    {:noreply, state}
  end
end
