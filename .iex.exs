alias Wumpex.Api

# Below is some code to locally run some tests on Wumpex
defmodule DummyBot do
  use Wumpex.Bot

  guild(DummyHandler)
  event(DummyHandler)
end

defmodule DummyHandler do
  require Logger

  def init do
    Logger.info("DummyHandler.init/0")

    nil
  end

  def handle(event, state) do
    Logger.debug("DummyHandler: #{inspect(event)}")

    state
  end
end
