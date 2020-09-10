defmodule WebsocketHelpers do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Readability.Specs

  @doc """
  Accepts a single websocket connection and closes after 100ms.
  """
  def accept_one(client) do
    Task.async(fn ->
      server = Socket.Web.listen!(8080)
      # Let the client know the server is ready to accept.
      send(client, :ready)
      client = Socket.Web.accept!(server)
      Socket.Web.accept!(client)

      Process.sleep(100)
    end)
  end

  @doc """
  Accepts a single websocket connection, echos back the first message and closes after 100ms.
  """
  def echo_one(client) do
    Task.async(fn ->
      server = Socket.Web.listen!(8080)
      # Let the client know the server is ready to accept.
      send(client, :ready)
      client = Socket.Web.accept!(server)
      Socket.Web.accept!(client)

      message = Socket.Web.recv!(client)
      Socket.Web.send!(client, message)

      Process.sleep(100)
    end)
  end

  @doc """
  Wait for the websocket server (see above methods) to indicate being ready to accept connections.
  """
  def wait_for_server do
    require ExUnit.Assertions
    import ExUnit.Assertions

    assert_receive :ready
  end
end
