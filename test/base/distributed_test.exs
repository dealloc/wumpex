defmodule Wumpex.Base.DistributedTest do
  use ExUnit.Case, async: false

  alias Wumpex.Base.Distributed

  @moduletag :integration
  doctest Wumpex.Base.Distributed

  @test_group "#{__MODULE__}"

  setup do
    on_exit(fn ->
      :pg2.delete(@test_group)
    end)
  end

  describe "Wumpex.Base.Distributed.join/2 should" do
    test "create the group if it does not exist" do
      refute Enum.any?(:pg2.which_groups(), fn group ->
        group == @test_group
      end)

      :ok = Distributed.join(@test_group, self())

      assert Enum.any?(:pg2.which_groups(), fn group ->
        group == @test_group
      end)
    end

    test "adds the pid to the group" do
      :ok = :pg2.create(@test_group)
      refute Enum.any?(:pg2.get_members(@test_group), fn member -> member == self() end)

      :ok = Distributed.join(@test_group, self())

      assert Enum.any?(:pg2.get_members(@test_group), fn member -> member == self() end)
    end
  end

  describe "Wumpex.Base.Distributed.members_of!/1 should" do
    test "throw if the group does not exist" do
      assert_raise RuntimeError, fn ->
        Distributed.members_of!(@test_group)
      end
    end

    test "return an empty list if the group is empty" do
      :pg2.create(@test_group)

      assert Distributed.members_of!(@test_group) == []
    end

    test "return members of the group" do
      :pg2.create(@test_group)
      :pg2.join(@test_group, self())

      assert Distributed.members_of!(@test_group) == [self()]
    end
  end
end
