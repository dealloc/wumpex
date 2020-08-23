defmodule Wumpex.ResourceTest do
  use ExUnit.Case

  doctest Wumpex.Resource

  alias Wumpex.Resource

  describe "to_atom/1 should" do
    test "transforms strings to existing atoms" do
      assert Resource.to_atom!("existing") == :existing
    end

    test "throws when the atom does not exist" do
      assert_raise ArgumentError, fn ->
        Resource.to_atom!("does-not-exist-ever!")
      end
    end
  end

  describe "to_datetime/1 should" do
    test "transform strings into DateTime" do
      {:ok, result, _offset} = DateTime.from_iso8601("2015-04-26T06:26:56.936000+00:00")
      assert Resource.to_datetime("2015-04-26T06:26:56.936000+00:00") == result
    end

    test "raise when invalid format is passed" do
      assert_raise MatchError, fn ->
        Resource.to_datetime("invalid")
      end
    end

    test "allow DateTime to be passed in, returns it" do
      {:ok, result, _offset} = DateTime.from_iso8601("2015-04-26T06:26:56.936000+00:00")
      assert Resource.to_datetime(result) == result
    end

    test "allow nil to be passed in, returns it" do
      assert nil == Resource.to_datetime(nil)
    end
  end

  describe "to_atomized_map/1 should" do
    test "return a map with atoms as keys" do
      data = %{"hello" => "world"}
      assert %{hello: "world"} == Resource.to_atomized_map(data)
    end

    test "ignores keys which are atoms" do
      data = %{"hello" => "world", hello2: "world2"}
      assert %{hello: "world", hello2: "world2"} == Resource.to_atomized_map(data)
    end

    test "throws when the keys are not known atoms" do
      data = %{"does-not-exist-ever!" => "world"}

      assert_raise ArgumentError, fn ->
        Resource.to_atomized_map(data)
      end
    end
  end
end
