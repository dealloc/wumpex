alias Wumpex.Api

# Below is some code to locally run some tests on Wumpex
defmodule DummyBot do
  use Wumpex.Bot

  event DummyHandler
end

defmodule DummyHandler do
  @behaviour Wumpex.Bot

  require Logger

  @impl Wumpex.Bot
  def init do
    Logger.info("DummyHandler.init/0")

    nil
  end

  @impl Wumpex.Bot
  def handle(event, state) do
    Logger.debug("DummyHandler: #{inspect(event)}")

    state
  end
end
