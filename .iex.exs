alias Wumpex.Api

# Below is some code to locally run some tests on Wumpex
defmodule DummyHandler do
  require Logger

  def start_wumpex do
    Wumpex.Sharding.start_link([
      handlers: [[handler: __MODULE__]]
    ])
  end

  def handle(event) do
    Logger.debug("DummyHandler: #{inspect(event)}")
  end
end
