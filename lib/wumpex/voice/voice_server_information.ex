defmodule Wumpex.Voice.VoiceServerInformation do
  @moduledoc false

  ###
  # This module contains helper methods for retrieving the VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE event.
  ###

  alias Wumpex.Gateway
  alias Wumpex.Gateway.Opcodes

  require Logger

  @typedoc """
  Contains all information about the voice server to connect to.

  This information is aggregated from `:VOICE_SERVER_UPDATE` and `:VOICE_STATE_UPDATE` events.
  """
  @type voice_server :: %{
          token: String.t(),
          guild_id: String.t(),
          endpoint: String.t(),
          session: String.t()
        }

  @doc """
  Attempt to retrieve the `t:voice_server/0` information from the gateway.

  This will dispatch an `Opcodes.voice_state_update/3` opcode on the event gateway.
  Once both the `:VOICE_STATE_UPDATE` and the `:VOICE_SERVER_UPDATE` event have been received
  the aggregated information will be returned.
  """
  @spec get_voice_server(
          shard :: Wumpex.shard(),
          guild :: String.t(),
          channel :: String.t(),
          user_id :: String.t(),
          timeout()
        ) :: voice_server()
  def get_voice_server(shard, guild, channel, user_id, timeout \\ 4_000) do
    try do
      Logger.debug("Attempting to fetch voice server from #{inspect(shard)}")
      Gateway.subscribe(shard)

      send_voice_update(shard, guild, channel)
      session = receive_voice_state(guild, channel, user_id, timeout)
      server = receive_voice_server(guild, timeout)

      Map.put(server, :session, session)
    after
      Gateway.unsubscribe(shard)
    end
  end

  # Dispatch the voice state update opcode.
  @spec send_voice_update(shard :: Wumpex.shard(), guild :: String.t(), channel :: String.t()) ::
          :ok
  defp send_voice_update(shard, guild, channel) do
    opcode =
      Opcodes.voice_state_update(guild, channel,
        mute: false,
        deafen: true
      )

    shard
    |> Wumpex.Gateway.via()
    |> Wumpex.Gateway.send_opcode(opcode)
  end

  # Receives the VOICE_STATE_UPDATE for the given guild, channel and user.
  @spec receive_voice_state(
          guild :: String.t(),
          channel :: String.t(),
          user_id :: String.t(),
          timeout()
        ) ::
          String.t()
  defp receive_voice_state(guild, channel, user_id, timeout) do
    user_id = String.to_integer(user_id)

    receive do
      {:event,
       %{
         name: :VOICE_STATE_UPDATE,
         payload: %{
           :guild_id => ^guild,
           :channel_id => ^channel,
           :user_id => ^user_id,
           :session_id => session
         }
       }} ->
        Logger.debug("Received VOICE_STATE_UPDATE")
        session
    after
      div(timeout, 2) ->
        raise "Could not connect to voice channel, is it full?"
    end
  end

  # Receives the VOICE_SERVER_UPDATE for the given guild.
  @spec receive_voice_server(guild :: String.t(), timeout()) :: voice_server()
  defp receive_voice_server(guild, timeout) do
    receive do
      {:event, %{name: :VOICE_SERVER_UPDATE, payload: %{:guild_id => ^guild} = event}} ->
        Logger.debug("Received VOICE_SERVER_UPDATE")
        event
    after
      div(timeout, 2) ->
        raise "Could not connect to voice channel, is it full?"
    end
  end
end
