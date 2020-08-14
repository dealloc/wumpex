defmodule Wumpex.Resource.ActivityTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Activity

  alias Wumpex.Resource.Activity

  describe "to_struct/1 should" do
    test "parse 'game' structs" do
      example = %{
        "name" => "Rocket League",
        "type" => 0, # Game
        "created_at" => "2015-04-26T06:26:56.936000+00:00",
        "timestamps" => %{},
        "application_id" => "id",
        "details" => "Details about the activity",
        "state" => "Ongoing",
        "emoji" => %{},
        "party" => %{},
        "assets" => %{},
        "secrets" => %{},
        "instance" => true,
        "flags" => 0
      }

      assert %Activity{
        name: "emoji",
        id: "308994132968210433",
        animated: true
      } = Activity.to_struct(example)
    end

    test "parse 'stream' structs" do

    end

    test "ignore missing fields" do
      assert %Activity{
        name: nil,
        id: nil,
        animated: nil
      } = Activity.to_struct(%{})
    end
  end
end
