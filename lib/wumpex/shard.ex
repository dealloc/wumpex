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

  use Supervisor

  @spec start_link(init_args :: keyword()) :: Supervisor.on_start()
  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_args) do
    children = [
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
