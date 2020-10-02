defmodule Wumpex.Gateway.OpcodesTest do
  @moduledoc false
  use ExUnit.Case

  alias Wumpex.Gateway.Opcodes

  doctest Wumpex.Gateway.Opcodes

  @test_token "MY_VERY_SECRET_TOKEN"
  @test_session "MY_VERY_SECRET_SESSION"

  describe "heartbeat/1 should" do
    test "generate a heartbeat with nil if no sequence exists yet" do
      assert %{"op" => 1, "d" => nil} == Opcodes.heartbeat(nil)
    end

    test "generate a heartbeat for the corresponding sequence" do
      for i <- 0..100 do
        assert %{"op" => 1, "d" => i} == Opcodes.heartbeat(i)
      end
    end

    test "only accept nil or numerical sequences" do
      assert_raise FunctionClauseError, fn ->
        Opcodes.heartbeat(%{})
      end

      assert_raise FunctionClauseError, fn ->
        Opcodes.heartbeat([])
      end

      assert_raise FunctionClauseError, fn ->
        Opcodes.heartbeat({})
      end

      assert_raise FunctionClauseError, fn ->
        Opcodes.heartbeat("0")
      end
    end
  end

  describe "identify/1 should" do
    test "generate an identify for the given token" do
      %{
        "op" => 2,
        "d" => %{
          "token" => @test_token
        }
      } = Opcodes.identify(@test_token, {0, 1})
    end

    test "contain the properties" do
      %{
        "d" => %{
          "properties" => %{
            "$os" => _,
            "$browser" => "wumpex",
            "$device" => _
          }
        }
      } = Opcodes.identify(@test_token, {0, 1})
    end
  end

  describe "resume/3 should" do
    test "generate a resume" do
      %{
        "op" => 6,
        "d" => %{
          "token" => @test_token,
          "session_id" => @test_session,
          "seq" => 42
        }
      } = Opcodes.resume(@test_token, 42, @test_session)
    end
  end
end
