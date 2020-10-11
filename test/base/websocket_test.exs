defmodule Wumpex.Base.WebsocketTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Wumpex.Base.Websocket

  @moduletag :integration
  doctest Wumpex.Base.Websocket

  describe "Wumpex.Base.Websocket should" do
    test "connect to websocket servers" do
      server = WebsocketHelpers.accept_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} =
        Websocket.start_link(WebsocketClient,
          host: "localhost",
          port: 8080,
          path: "/",
          timeout: 100,
          worker: self()
        )

      assert Process.alive?(client)

      Task.await(server, 1_000)
    end

    test "send messages to it's worker in :text mode" do
      server = WebsocketHelpers.echo_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} =
        Websocket.start_link(WebsocketClient,
          host: "localhost",
          port: 8080,
          path: "/",
          timeout: 100,
          worker: self()
        )

      Websocket.send(client, {:text, "Hello world"})
      assert_receive {:text, "Hello world"}

      Task.await(server, 1_000)
    end

    test "send messages to it's worker in :binary mode" do
      server = WebsocketHelpers.echo_one(self())
      WebsocketHelpers.wait_for_server()

      {:ok, client} =
        Websocket.start_link(WebsocketClient,
          host: "localhost",
          port: 8080,
          path: "/",
          timeout: 100,
          worker: self()
        )

      Websocket.send(client, {:binary, "Hello world"})
      assert_receive {:binary, "Hello world"}

      Task.await(server, 1_000)
    end
  end
end
