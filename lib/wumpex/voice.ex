defmodule Wumpex.Voice do
  def connect(shard, guild, channel) do
    {:ok, voice} = Wumpex.Voice.Manager.start_link([
      shard: shard,
      guild: guild,
      channel: channel
    ])

    voice
  end
end
