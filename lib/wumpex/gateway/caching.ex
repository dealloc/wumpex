defmodule Wumpex.Gateway.Caching do
  @moduledoc """
  Handles the caching and tracking of state (and state updates), this is the second stage of event processing in Wumpex.

  The first stage of event processing is mainly receiving and buffering events until the next stages are ready to process more.
  If events start arriving faster than the consumers can handle them, the `Wumpex.Gateway.EventProducer` will start buffering them.

  The second stage of event processing is the cache, used for tracking state (as described in the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#tracking-state)).
  The `Wumpex.Gateway.Caching` stage will check for events that signal a change in state (eg. user update, presence update, ...) and update the relevant state (if it's being tracked).

  Finally, the third and last state of event processing is the `Wumpex.Gateway.EventConsumer`, which handles dispatching the incoming events to the respective handlers.
  There can be multiple instances of `Wumpex.Gateway.EventConsumer`, since one will be started for each event handler.
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
