defmodule Wumpex.Guild.Client do
  @moduledoc """
  Represents a single guild in Wumpex.

  The client module is basically an event handler for a specific guild.
  Keep in mind that due to sharding, there might be more than one handler for a specific guild active.
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

  def handle_info({:event, event}, state) do
    Logger.info(inspect(event))

    {:noreply, state}
  end
end
