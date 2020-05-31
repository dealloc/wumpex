defmodule Wumpex.Guild.Guilds do
  @moduledoc """
  Tracks all active `Wumpex.Guild.Client` processes for a given `Wumpex.Shard`.

  This module acts as both a `Registry`, allowing to look up clients by their Guild ID, and a `DynamicSupervisor` (by monitoring those client processes).
  Doubles as a `Registry` and a `DynamicSupervisor`
  """

  use DynamicSupervisor

  @spec start_link(options :: keyword()) :: Supervisor.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new `Wumpex.Guild.Client` instance which monitors the guild corresponding with `guild_id`.

  This is called when a guild becomes available (eg. the bot is added to it, or on startup).
  """
  @spec start_guild(guild_sup :: pid(), guild_id :: String.t()) :: Supervisor.on_start_child()
  def start_guild(guild_sup, guild_id) do
    DynamicSupervisor.start_child(guild_sup, {Wumpex.Guild.Client, guild_id: guild_id})
  end

  @doc """
  Requests the `Wumpex.Guild.Client` instance for the given `guild_id` to exit.

  This is called whenever a guild is no longer available (eg. the bot was removed from that guild).
  """
  @spec stop_guild(guild_id :: String.t()) :: :ok
  def stop_guild(guild_id) do
    [{guild, _}] = Registry.lookup(__MODULE__, guild_id)

    send(guild, {:close, :normal})
    :ok
  end

  @doc """
  Dispatch a given `event` to the `Wumpex.Guild.Client` process for the guild corresponding with `guild_id`.
  """
  @spec dispatch!(guild_id :: String.t(), event :: any()) :: :ok
  def dispatch!(guild_id, event) do
    [{guild, _}] = Registry.lookup(__MODULE__, guild_id)

    send(guild, {:event, event})
    :ok
  end
end