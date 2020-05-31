defmodule Wumpex.Guild.Client do
  @moduledoc """
  Represents a single guild in Wumpex.

  The client module is basically an event handler for a specific guild.
  Keep in mind that due to sharding, there might be more than one handler for a specific guild active.

  The client module is started when the gateway is notified a guild becomes available (see `Wumpex.Gateway.EventHandler.dispatch/3`).
  The guild information is not passed to the process for a simple reason:
  if the guild process would crash, the supervisor (see `Wumpex.Guild.Guilds`) would restart with the settings that it was originally given.
  However, if the guild information had changed since then, the guild would be given invalid information.

  If you require state, it's recommended to start an `Agent` which tracks the current guild information for you.
  """

  use GenServer, restart: :transient

  require Logger

  @spec start_link(options :: keyword()) :: GenServer.on_start()
  def start_link(guild_id: guild_id) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {Wumpex.Guild.Guilds, guild_id}})
  end

  @impl GenServer
  def init(_stack) do
    {:ok, []}
  end

  # Handles requests to close down the guild!
  @impl GenServer
  def handle_info({:close, reason}, state), do: {:stop, reason, state}

  def handle_info({:event, {event_name, event}}, state) do
    Logger.info(inspect({event_name, event}))

    {:noreply, state}
  end
end
