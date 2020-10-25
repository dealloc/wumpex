defmodule Wumpex.Gateway.Caching do
  use GenStage

  require Logger

  @typedoc """
  Represents the options to be passed to `start_link/1`.

  Contains the following fields:
  * `:producer` - The `t:pid/0` of the producer to subscribe to.
  """
  @type options :: [
          producer: pid()
        ]

  @doc false
  @spec start_link(options :: keyword()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, options)
  end

  @impl GenStage
  def init(producer: producer) do
    {:producer_consumer, nil,
     subscribe_to: [
       {producer, max_demand: 2, min_demand: 0}
     ],
     dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    # Caching should process events and optionally update the cache when relevant events are sent.

    {:noreply, events, state}
  end
end
