defmodule Wumpex.Gateway.Consumers.EventConsumer do
  use GenStage

  require Logger

  @doc false
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, options)
  end

  @impl GenStage
  def init(producer: producer, handler: handler) do
    {:consumer, handler,
     subscribe_to: [
       {producer, max_demand: 1, min_demand: 0}
     ]}
  end

  @impl GenStage
  def handle_events(events, _from, [handler: handler] = state) do
    # Logger.debug("EventConsumer: #{inspect(events)}")

    handler.handle(events)

    {:noreply, [], state}
  end
end
