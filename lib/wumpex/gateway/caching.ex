defmodule Wumpex.Gateway.Caching do
  @moduledoc """
  Handles state tracking as described in the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#tracking-state).

  This is the second stage in the event processing pipeline, right after `Wumpex.Gateway.EventProducer`.
  Once an event is properly handled and the state is up to date, the event will be dispatched to all the listeners.
  """

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
