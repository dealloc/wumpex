defmodule Wumpex.Gateway.Guild.Coordinator do
  @moduledoc """
  Tracks all active `Wumpex.Gateway.Guild.Client` processes for a given `Wumpex.Shard`.

  This module implements the `Wumpex.Base.Coordinator` behaviour.
  """

  use Wumpex.Base.Coordinator

  @doc """
  Start a new `Wumpex.Gateway.Guild.Client` instance which monitors the guild corresponding with `guild_id`.

  This is called when a guild becomes available (eg. the bot is added to it, or on startup).
  """
  @spec start_guild(guild_sup :: pid(), guild_id :: String.t()) :: Supervisor.on_start_child()
  def start_guild(guild_sup, guild_id) do
    DynamicSupervisor.start_child(guild_sup, {Wumpex.Gateway.Guild.Client, guild_id: guild_id})
  end

  @doc """
  Start a new `child_spec` listener under the guilds supervisor.

  This allows to attach custom listeners, such as for temporary listeners.
  """
  @spec start_guild_listener(guild_sup :: pid(), child_spec :: Supervisor.child_spec()) ::
          Supervisor.on_start_child()
  def start_guild_listener(guild_sup, child_spec) do
    DynamicSupervisor.start_child(guild_sup, child_spec)
  end

  @doc """
  Requests the `Wumpex.Gateway.Guild.Client` instance for the given `guild_id` to exit.

  This is called whenever a guild is no longer available (eg. the bot was removed from that guild).
  """
  @spec stop_guild(guild_id :: String.t()) :: :ok
  def stop_guild(guild_id) do
    broadcast(guild_id, {:close, :normal})
  end

  @doc """
  Dispatch a given `event` to the `Wumpex.Gateway.Guild.Client` process for the guild corresponding with `guild_id`.
  """
  @spec dispatch!(guild_id :: String.t(), event :: any()) :: :ok
  def dispatch!(guild_id, event) do
    broadcast(guild_id, {:event, event})
  end
end
