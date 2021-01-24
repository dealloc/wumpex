defmodule WumpexTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response

  @moduletag :integration

  doctest Wumpex

  setup do
    key = Wumpex.token()

    on_exit(fn ->
      Application.put_env(:wumpex, :key, key)
      Application.delete_env(:wumpex, :user_id)
    end)
  end

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

  describe "Wumpex.user_id/0 should" do
    test_with_server "return the user ID" do
      route("/users/@me", Response.ok("{\"id\": 123456789}"))
      Application.put_env(:wumpex, :endpoint, "http://localhost:#{FakeServer.port()}")

      assert 123_456_789 = Wumpex.user_id()
      assert hits() == 1
    end

    test_with_server "only hits the API once" do
      route("/users/@me", Response.ok("{\"id\": 123456789}"))
      Application.put_env(:wumpex, :endpoint, "http://localhost:#{FakeServer.port()}")

      assert 123_456_789 = Wumpex.user_id()
      assert 123_456_789 = Wumpex.user_id()
      assert hits() == 1
    end
  end
end
