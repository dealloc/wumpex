defmodule Wumpex.Resource.PresenceUpdateTest do
  use ExUnit.Case

  doctest Wumpex.Resource.PresenceUpdate

  alias Wumpex.Resource.Activity
  alias Wumpex.Resource.ClientStatus
  alias Wumpex.Resource.PresenceUpdate
  alias Wumpex.Resource.User

  describe "to_struct/1 should" do
    test "parse an example for PresenceUpdate" do
      example = %{
        "user" => %{},
        "roles" => ["first", "second"],
        "game" => %{},
        "guild_id" => "snowflake",
        "status" => "dnd",
        "activities" => [],
        "client_status" => %{},
        "premium_since" => "2017-07-11T17:27:07.299000+00:00",
        "nick" => nil
      }

      assert %PresenceUpdate{
               user: %User{},
               roles: ["first", "second"],
               game: %Activity{},
               guild_id: "snowflake",
               status: "dnd",
               activities: [],
               client_status: %ClientStatus{},
               premium_since: ~U[2017-07-11 17:27:07.299000Z],
               nick: nil
             } = PresenceUpdate.to_struct(example)
    end
  end
end
