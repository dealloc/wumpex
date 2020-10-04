defmodule Wumpex.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry,
       keys: :duplicate,
       name: Wumpex.Gateway.Guild.Coordinator,
       partitions: System.schedulers_online()},
      {Wumpex.Api.Ratelimit, []},
      # Normally the shard configuration comes from the Discord API, we're taking shortcuts here
      {Wumpex.Shard, [shard: {0, 1}, gateway: "gateway.discord.gg"]}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Wumpex.Supervisor
    )
  end
end
