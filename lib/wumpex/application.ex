defmodule Wumpex.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry,
       keys: :unique, name: Wumpex.Guild.Guilds, partitions: System.schedulers_online()},
      # Normally the shard configuration comes from the Discord API, we're taking shortcuts here
      {Wumpex.Shard, [shard: {0, 1}, gateway: "wss://gateway.discord.gg"]}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Wumpex.Supervisor
    )
  end
end
