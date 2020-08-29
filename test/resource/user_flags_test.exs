defmodule Wumpex.Resource.UserFlagsTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.UserFlags

  alias Wumpex.Resource.UserFlags

  describe "to_struct/1 should" do
    test "parse no user flags" do
      assert %UserFlags{
        none: true,
        discord_employee: false,
        discord_partner: false,
        hypesquad_events: false,
        bug_hunter_level_1: false,
        house_bravery: false,
        house_brilliance: false,
        house_balance: false,
        early_supporter: false,
        team_user: false,
        system: false,
        bug_hunter_level_2: false,
        verified_bot: false,
        verified_bot_developer: false
      } = UserFlags.to_struct(0)
    end

    test "parse set bit flags" do
      assert %UserFlags{
        none: false,
        discord_employee: true,
        discord_partner: true,
        hypesquad_events: true,
        bug_hunter_level_1: false,
        house_bravery: false,
        house_brilliance: false,
        house_balance: false,
        early_supporter: false,
        team_user: false,
        system: false,
        bug_hunter_level_2: false,
        verified_bot: false,
        verified_bot_developer: false
      } = UserFlags.to_struct(23)
    end
  end
end
