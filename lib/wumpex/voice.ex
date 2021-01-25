defmodule Wumpex.Voice do
  @moduledoc """
  Contains functionality for connecting and interacting with voice connections.
  """

  alias Wumpex.Voice.Manager

  @doc """
  Connects to a given voice channel.

  Returns `{:ok, pid}` where `pid` is the `t:pid/0` of the voice connection.

  Takes the following parameters:
  * `:shard` - The shard on which the `:guild` is running.
  * `:guild` - The ID of the guild the given channel is in.
  * `:channel` - The ID of the channel to connect to.
  """
  @spec connect(shard :: Wumpex.shard(), guild :: Wumpex.guild(), channel :: Wumpex.channel()) ::
          GenServer.on_start()
  def connect(shard, guild, channel) do
    Manager.start_link(
      shard: shard,
      guild: guild,
      channel: channel
    )
  end

  @doc """
  Disconnects the given voice connection from it's currently connected channel.
  """
  @spec disconnect(voice :: pid()) :: :ok
  def disconnect(voice) do
    GenServer.call(voice, {:connect, [channel: nil]})
    :ok
  end

  @doc """
  Set the voice state for the given voice connection.
  This involves (un)muting and (un)deafening.

  The `:options` parameter is a list that takes either `:mute` or `:deafen` as it's members.
  Passing in either of these two will cause the bot to mute or deafen (respectively).
  """
  @spec set_state(voice :: pid(), options :: list(atom())) :: :ok
  def set_state(voice, options) do
    options =
      options
      |> Enum.map(fn option -> {option, true} end)
      |> Keyword.take([:mute, :deafen])

    GenServer.call(voice, {:connect, options})
    :ok
  end

  @doc """
  Requests to play the given enumerable/stream on the given voice connection.
  The `stream` parameter can be both a list (or other enumerable) or a [`Stream`](https://hexdocs.pm/elixir/Stream.html).

  This method will return a `t:reference/0` that refers to this audio request.
  If you want to cancel the playback (either while it's playing or when it's still queued),
  you can use this reference to identity the playback request.
  """
  @spec play(voice :: pid(), stream :: Enum.t()) :: reference()
  def play(voice, stream) do
    GenServer.call(voice, {:play, stream})
  end
end
