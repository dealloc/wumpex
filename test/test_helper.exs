ExUnit.start()

defmodule WebsocketHelpers do
  def accept_one, do: Task.async(fn ->
    server = Socket.Web.listen! 8080
    client = Socket.Web.accept!(server)
    Socket.Web.accept!(client)

    Process.sleep(100)
  end)

  def echo_one, do: Task.async(fn ->
    server = Socket.Web.listen! 8080
    client = Socket.Web.accept!(server)
    Socket.Web.accept!(client)

    message = Socket.Web.recv!(client)
    Socket.Web.send!(client, message)

    Process.sleep(100)
  end)
end
