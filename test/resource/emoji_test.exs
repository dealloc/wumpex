defmodule Wumpex.Resource.EmojiTest do
  use ExUnit.Case

  alias Wumpex.Resource.Emoji
  alias Wumpex.Resource.User

  describe "to_struct/1 should" do
    test "parse an example for Emoji" do
      example = %{
        "animated" => false,
        "id" => "41771983429993937",
        "managed" => false,
        "name" => "LUL",
        "require_colons" => true,
        "roles" => ["41771983429993000", "41771983429993111"],
        "user" => %{}
      }

      assert %Emoji{
               animated: false,
               id: "41771983429993937",
               managed: false,
               name: "LUL",
               require_colons: true,
               roles: ["41771983429993000", "41771983429993111"],
               user: %User{}
             } = Emoji.to_struct(example)
    end
  end
end
