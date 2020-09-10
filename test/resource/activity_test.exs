defmodule Wumpex.Resource.ActivityTest do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  use ExUnit.Case

  doctest Wumpex.Resource.Activity

  alias Wumpex.Resource.Activity
  alias Wumpex.Resource.Activity.Assets
  alias Wumpex.Resource.Activity.Emoji
  alias Wumpex.Resource.Activity.Flags
  alias Wumpex.Resource.Activity.Party
  alias Wumpex.Resource.Activity.Secrets
  alias Wumpex.Resource.Activity.Timestamps

  describe "to_struct/1 should" do
    test "parse 'game' structs" do
      example = %{
        "name" => "Rocket League",
        # Game
        "type" => 0,
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
               name: "Rocket League",
               type: 0,
               created_at: ~U[2015-04-26 06:26:56.936000Z],
               timestamps: %Timestamps{},
               application_id: "id",
               details: "Details about the activity",
               state: "Ongoing",
               emoji: %Emoji{},
               party: %Party{},
               assets: %Assets{},
               secrets: %Secrets{},
               instance: true,
               flags: %Flags{}
             } = Activity.to_struct(example)
    end

    test "parse 'stream' structs" do
    end

    test "ignore missing fields" do
      example = %{
        "name" => "Rocket League",
        # Game
        "type" => 0,
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
        "flags" => 0,
        "random" => "testing random",
        "missing" => "testing missing",
        "fields" => "testing fields"
      }

      assert %Activity{
               name: "Rocket League",
               type: 0,
               created_at: ~U[2015-04-26 06:26:56.936000Z],
               timestamps: %Timestamps{},
               application_id: "id",
               details: "Details about the activity",
               state: "Ongoing",
               emoji: %Emoji{},
               party: %Party{},
               assets: %Assets{},
               secrets: %Secrets{},
               instance: true,
               flags: %Flags{}
             } = Activity.to_struct(example)
    end
  end
end
