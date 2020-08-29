defmodule Wumpex.Resource.Activity.FlagsTest do
  @moduledoc false
  use ExUnit.Case
  use Bitwise

  doctest Wumpex.Resource.Activity.Flags

  alias Wumpex.Resource.Activity.Flags

  describe "to_struct/1 should" do
    test "detect the 'instance' flag" do
      flags = 1 <<< 0

      assert %Flags{
               instance: true,
               join: false,
               spectate: false,
               join_request: false,
               sync: false,
               play: false
             } = Flags.to_struct(flags)
    end

    test "detect the 'join' flag" do
      flags = 1 <<< 1

      assert %Flags{
               instance: false,
               join: true,
               spectate: false,
               join_request: false,
               sync: false,
               play: false
             } = Flags.to_struct(flags)
    end

    test "detect the 'spectate' flag" do
      flags = 1 <<< 2

      assert %Flags{
               instance: false,
               join: false,
               spectate: true,
               join_request: false,
               sync: false,
               play: false
             } = Flags.to_struct(flags)
    end

    test "detect the 'join_request' flag" do
      flags = 1 <<< 3

      assert %Flags{
               instance: false,
               join: false,
               spectate: false,
               join_request: true,
               sync: false,
               play: false
             } = Flags.to_struct(flags)
    end

    test "detect the 'sync' flag" do
      flags = 1 <<< 4

      assert %Flags{
               instance: false,
               join: false,
               spectate: false,
               join_request: false,
               sync: true,
               play: false
             } = Flags.to_struct(flags)
    end

    test "detect the 'play' flag" do
      flags = 1 <<< 5

      assert %Flags{
               instance: false,
               join: false,
               spectate: false,
               join_request: false,
               sync: false,
               play: true
             } = Flags.to_struct(flags)
    end

    test "detect combined flags" do
      flags = 1 <<< 1 ||| 1 <<< 4

      assert %Flags{
               instance: false,
               join: true,
               spectate: false,
               join_request: false,
               sync: true,
               play: false
             } = Flags.to_struct(flags)
    end
  end
end
