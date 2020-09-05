defmodule Wumpex.Resource.Guild.ChannelFlagsTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Guild.ChannelFlags

  alias Wumpex.Resource.Guild.ChannelFlags

  describe "to_struct/1 should" do
    test "parse no channel flags" do
      assert %ChannelFlags{
               suppress_join_notifications: false,
               suppress_premium_subscriptions: false
             } = ChannelFlags.to_struct(0)
    end

    test "parse set bit flags" do
      assert %ChannelFlags{
               suppress_join_notifications: true,
               suppress_premium_subscriptions: false
             } = ChannelFlags.to_struct(1)
    end
  end
end
