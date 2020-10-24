defmodule Wumpex.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Wumpex.Api.Ratelimit, []}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Wumpex.Supervisor
    )
  end
end
