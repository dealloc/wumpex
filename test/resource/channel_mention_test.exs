defmodule Wumpex.Resource.ChannelMentionTest do
  use ExUnit.Case

  alias Wumpex.Resource.ChannelMention

  describe "to_struct/1 should" do
    test "parse an example for a channel mention" do
      example = %{
        "id" => "746840255222513634",
        "guild_id" => "746840255222513634",
        "type" => 0,
        "name" => "Test channel"
      }

      assert %ChannelMention{
               id: "746840255222513634",
               guild_id: "746840255222513634",
               type: 0,
               name: "Test channel"
             } = ChannelMention.to_struct(example)
    end
  end
end
