defmodule WumpexTest do
  use ExUnit.Case

  doctest Wumpex

  describe "Wumpex.token/0 should" do
    test "return the configured token when it's a string" do
      Application.put_env(:wumpex, :key, "some-string")

      assert Wumpex.token() == "some-string"
    end

    test "return the configured token when it's nil" do
      Application.put_env(:wumpex, :key, nil)

      assert Wumpex.token() == nil
    end

    test "return nil when the token is not configured" do
      Application.delete_env(:wumpex, :key)

      assert Wumpex.token() == nil
    end

    test "raise when the configured token is not nil or a string" do
      Application.put_env(:wumpex, :key, [])

      assert_raise RuntimeError, fn ->
        Wumpex.token()
      end
    end
  end
end
