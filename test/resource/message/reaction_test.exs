defmodule Wumpex.Resource.Message.ReactionTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Message.Reaction

  alias Wumpex.Resource.Emoji
  alias Wumpex.Resource.Message.Reaction

  describe "to_struct/1 should" do
    test "parse example" do
      example = %{
        "count" => 1,
        "me" => false,
        "emoji" => %{}
      }

      assert %Reaction{
               count: 1,
               me: false,
               emoji: %Emoji{}
             } = Reaction.to_struct(example)
    end
  end
end
