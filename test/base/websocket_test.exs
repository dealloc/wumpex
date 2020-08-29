defmodule Wumpex.Base.WebsocketTest do
  @moduledoc false
  use ExUnit.Case, async: false

  @moduletag :integration
  doctest Wumpex.Base.Websocket

  alias Wumpex.Base.Websocket

  describe "Wumpex.Base.Websocket should" do
    test "connect to websocket servers" do
      server = WebsocketHelpers.accept_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} = Websocket.start_link(url: "ws://localhost:8080", worker: self())
      assert Process.alive?(client)

      Task.await(server, 1_000)
    end

    test "send messages to it's worker in :text mode" do
      server = WebsocketHelpers.echo_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} = Websocket.start_link(url: "ws://localhost:8080", worker: self())
      Websocket.send(client, "Hello world", mode: :text)
      assert_receive {:"$gen_cast", {{:text, "Hello world"}, _pid}}

      Task.await(server, 1_000)
    end

    test "send messages to it's worker in :binary mode" do
      server = WebsocketHelpers.echo_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} = Websocket.start_link(url: "ws://localhost:8080", worker: self())
      Websocket.send(client, "Hello world", mode: :binary)
      assert_receive {:"$gen_cast", {{:binary, "Hello world"}, _pid}}

      Task.await(server, 1_000)
    end
  end
end
