defmodule Wumpex.Gateway.Caching do
  # https://discord.com/developers/docs/topics/gateway#tracking-state
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
    # Once the handler logic for actually handling events is ready, change this to :producer_consumer
    {:consumer, nil, subscribe_to: [{producer, max_demand: 2, min_demand: 0}]}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Process.sleep(5_000)
    Logger.info("Processed #{Enum.count(events)} events.")
    # IO.inspect(events, label: "Cache")

    {:noreply, [], state}
  end
end
