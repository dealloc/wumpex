defmodule Wumpex.Voice do
  def connect(shard, guild, channel) do
    {:ok, voice} = Wumpex.Voice.Connection.start_link(shard: shard, guild: guild)

    shard
    |> Wumpex.Gateway.via()
    |> Wumpex.Gateway.send_opcode(%{
      "op" => 4,
      "d" => %{
        "guild_id" => guild,
        "channel_id" => channel,
        "self_mute" => true,
        "self_deaf" => true
      }
    })

    voice
  end
end
