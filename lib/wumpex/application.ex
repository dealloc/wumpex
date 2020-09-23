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
      :poolboy.child_spec(:wumpex_buckets, [
        name: {:local, :wumpex_buckets},
        worker_module: Wumpex.Api.Ratelimit.StatelessBucket,
        size: Application.get_env(:wumpex, :buckets, 4),
        max_overflow: Application.get_env(:wumpex, :buckets, 4)
      ]),
      # Normally the shard configuration comes from the Discord API, we're taking shortcuts here
      {Wumpex.Shard, [shard: {0, 1}, gateway: "wss://gateway.discord.gg"]}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Wumpex.Supervisor
    )
  end
end
