alias Wumpex.Api

# Below is some code to locally run some tests on Wumpex
defmodule DummyHandler do
  require Logger

  def start_wumpex do
    Wumpex.Sharding.start_link([
      handlers: [[handler: __MODULE__]]
    ])
  end

  def init do
    Logger.info("DummyHandler.init/0")

    nil
  end

  def handle(event, state) do
    Logger.debug("DummyHandler: #{inspect(event)}")

    state
  end
end
