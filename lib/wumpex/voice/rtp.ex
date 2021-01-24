defmodule Wumpex.Voice.Rtp do
  @moduledoc """
  Contains methods for generating RTP packets.

  Implementation based on the [official documentation](https://discord.com/developers/docs/topics/voice-connections#encrypting-and-sending-voice-voice-packet-structure).
  """

  @doc """
  Generates a "silent" frame.
  """
  @spec silence :: <<_::24>>
  def silence, do: <<0xF8, 0xFF, 0xFE>>

  @doc """
  Encodes the given data as an encrypted RTP packet.
  """
  @spec encode(
          data :: binary(),
          sequence :: non_neg_integer(),
          time :: non_neg_integer(),
          ssrc :: non_neg_integer(),
          key :: binary()
        ) :: binary()
  def encode(data, sequence, time, ssrc, key) do
    header = header(sequence, time, ssrc)
    nonce = header <> <<0::size(96)>>
    payload = Kcl.secretbox(data, nonce, key)

    header <> payload
  end

  # Generates an RTP header.
  defp header(sequence, time, ssrc),
    do: <<0x80, 0x78, sequence::size(16), time::size(32), ssrc::size(32)>>
end
