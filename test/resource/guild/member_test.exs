defmodule Wumpex.Resource.Guild.MemberTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Guild.Member

  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.User

  describe "to_struct/1 should" do
    test "parse official example" do
      example = %{
        "user" => %{},
        "nick" => "NOT API SUPPORT",
        "roles" => [],
        "joined_at" => "2015-04-26T06:26:56.936000+00:00",
        "deaf" => false,
        "mute" => false
      }

      assert %Member{
        user: %User{},
        nick: "NOT API SUPPORT",
        roles: [],
        joined_at: ~U[2015-04-26 06:26:56.936000Z],
        deaf: false,
        mute: false
      } = Member.to_struct(example)
    end
  end
end
