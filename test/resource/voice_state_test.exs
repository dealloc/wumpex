defmodule Wumpex.Resource.VoiceStateTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.VoiceState

  alias Wumpex.Resource.VoiceState

  describe "to_struct/1 should" do
    test "parse the official example" do
      example = %{
        "channel_id" => "157733188964188161",
        "deaf" => false,
        "mute" => false,
        "self_deaf" => false,
        "self_mute" => true,
        "session_id" => "90326bd25d71d39b9ef95b299e3872ff",
        "suppress" => false,
        "user_id" => "80351110224678912"
      }

      assert %VoiceState{
        channel_id: "157733188964188161",
        deaf: false,
        mute: false,
        self_deaf: false,
        self_mute: true,
        session_id: "90326bd25d71d39b9ef95b299e3872ff",
        suppress: false,
        user_id: "80351110224678912"
      } = VoiceState.to_struct(example)
    end
  end
end
