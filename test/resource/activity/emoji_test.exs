defmodule Wumpex.Resource.Activity.EmojiTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Activity.Emoji

  alias Wumpex.Resource.Activity.Emoji

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "name" => "emoji",
        "id" => "308994132968210433",
        "animated" => true
      }

      assert %Emoji{
               name: "emoji",
               id: "308994132968210433",
               animated: true
             } = Emoji.to_struct(example)
    end

    test "ignore missing fields" do
      assert %Emoji{
               name: nil,
               id: nil,
               animated: nil
             } = Emoji.to_struct(%{})
    end
  end
end
