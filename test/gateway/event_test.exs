defmodule Wumpex.Gateway.EventTest do
  @moduledoc false
  use ExUnit.Case

  alias Wumpex.Gateway.Event

  doctest Wumpex.Gateway.Event

  describe "Event.guild/1 should" do
    test "return nil if there's no guild specific event" do
      event = %Event{
        name: :TEST_EVENT,
        payload: %{},
        sequence: 0,
        shard: {0, 0}
      }

      assert nil == Event.guild(event)
    end

    test "return the guild ID when the event is GUILD_CREATE" do
      event = %Event{
        name: :GUILD_CREATE,
        payload: %{id: 123_456_789},
        sequence: 0,
        shard: {0, 0}
      }

      assert 123_456_789 = Event.guild(event)
    end

    test "return the guild ID when it's as an atom key" do
      event = %Event{
        name: :TEST_EVENT,
        payload: %{guild_id: 123_456_789},
        sequence: 0,
        shard: {0, 0}
      }

      assert 123_456_789 = Event.guild(event)
    end

    test "return the guild ID when it's as an string key" do
      event = %Event{
        name: :TEST_EVENT,
        payload: %{"guild_id" => 123_456_789},
        sequence: 0,
        shard: {0, 0}
      }

      assert 123_456_789 = Event.guild(event)
    end
  end
end
