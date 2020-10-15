defmodule Wumpex.Gateway.Caching do
  use GenStage

  require Logger

  @type options :: [
          producer: pid()
        ]

  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, options)
  end

  @impl GenStage
  def init(producer: producer) do
    {:consumer, nil, subscribe_to: [{producer, max_demand: 1, min_demand: 0}]}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    # Inspect the events.
    IO.inspect(events, label: "Cache")

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end
end
