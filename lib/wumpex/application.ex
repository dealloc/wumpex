defmodule Wumpex.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Wumpex.Api.Ratelimit, []},
      {Wumpex.Sharding.ShardLedger, []},
      {Wumpex.Voice.VoiceLedger, []},
      {DynamicSupervisor, strategy: :one_for_one, name: Wumpex.GatewaySupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: Wumpex.GatewayListenerSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: Wumpex.VoiceSupervisor},
      %{id: :pg, start: {:pg, :start_link, [:wumpex]}}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Wumpex.Supervisor
    )
  end
end
