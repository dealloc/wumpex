alias Wumpex.Api

# Below is some code to locally run some tests on Wumpex
defmodule DummyBot do
  use Wumpex.Bot

  guild(DummyHandler)
  event(DummyHandler)

  def voice do
    # Wumpex.Voice.connect({0, 1}, 706_426_601_608_577_036, 706_426_601_608_577_041)
    Wumpex.Voice.connect({0, 1}, 790_949_880_292_966_410, 790_949_880_754_864_128)
  end

  def play(voice) do
    stream = File.read!("/home/dealloc/encoded.opus")
    Wumpex.Voice.play(voice, :erlang.binary_to_term(stream))
  end
end

defmodule DummyHandler do
  require Logger

  def init do
    Logger.info("DummyHandler.init/0")

    nil
  end

  def handle(event, state) do
    Logger.debug("DummyHandler: #{inspect(event, limit: :infinity)}")

    state
  end
end
