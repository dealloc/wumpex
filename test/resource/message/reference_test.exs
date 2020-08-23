defmodule Wumpex.Resource.Message.ReferenceTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Message.Reference

  alias Wumpex.Resource.Message.Reference

  describe "to_struct/1 should" do
    test "parse example" do
      example = %{
        message_id: "73193882359173120",
        channel_id: "73193882359173121",
        guild_id: "73193882359173122"
      }

      assert %Reference{
        message_id: "73193882359173120",
        channel_id: "73193882359173121",
        guild_id: "73193882359173122"
      } = Reference.to_struct(example)
    end
  end
end
