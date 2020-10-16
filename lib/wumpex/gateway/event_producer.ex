defmodule Wumpex.Gateway.EventProducer do
  @moduledoc """
  This module handles the processing of events dispatched by the gateway, it's the first stage of event processing in Wumpex.

  The first stage of event processing is mainly receiving and buffering events until the next stages are ready to process more.
  If events start arriving faster than the consumers can handle them, the `Wumpex.Gateway.EventProducer` will start buffering them.

  The second stage of event processing is the cache, used for tracking state (as described in the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#tracking-state)).
  The `Wumpex.Gateway.Caching` stage will check for events that signal a change in state (eg. user update, presence update, ...) and update the relevant state (if it's being tracked).

  Finally, the third and last state of event processing is the `Wumpex.Gateway.EventConsumer`, which handles dispatching the incoming events to the respective handlers.
  """

  use GenStage

  require Logger

  @typedoc """
  The state of the producer.

  The first element of the tuple is an Erlang queue, the second item is an integer representing the pending demand.
  """
  @type state :: {:queue.queue(), non_neg_integer()}

  @typedoc """
  Represents an event that can be sent to the producer.
  """
  @type event :: {event_name :: atom(), event :: map()}

  @doc """
  Dispatch an event to the given producer.

  This puts the event in the processing pipeline for caching and eventually handling.
  """
  @spec dispatch(producer :: pid(), event_name :: atom(), event :: map()) :: :ok
  def dispatch(producer, event_name, event) do
    send(producer, {:event, {event_name, event}})
  end

  @doc false
  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  @impl GenStage
  def init(_options) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_demand(incoming, {queue, demand}) do
    pop_events([], queue, demand + incoming)
  end

  # Called when a new event is published but there's no demand, we queue the event.
  @impl GenStage
  def handle_info({:event, event}, {queue, 0}) do
    queue = :queue.in(event, queue)

    {:noreply, [], {queue, 0}}
  end

  # Called when a new event is published, and there's already demand for an event.
  @impl GenStage
  def handle_info({:event, event}, {queue, demand}) do
    # Push the event on the queue (there might be other queued events so we can't just pop).
    queue = :queue.in(event, queue)

    # There's always at least one item in the queue (since we just pushed one).
    # credo:disable-for-next-line Credo.Check.Refactor.VariableRebinding
    {{:value, event}, queue} = :queue.out(queue)
    {:noreply, [event], {queue, demand - 1}}
  end

  # No more demand to process, return the already queued events.
  @spec pop_events([event()], :queue.queue(event()), non_neg_integer()) ::
          {:noreply, [event()], state()}
  defp pop_events(events, queue, 0) do
    {:noreply, events, {queue, 0}}
  end

  # Attempts to push as many events from the queue as demand requests.
  defp pop_events(events, queue, demand) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        # We took an item off, so demand increased and decreased by 1.
        pop_events(events ++ [event], queue, demand - 1)

      {:empty, queue} ->
        # No queued events, don't decrease demand.
        {:noreply, events, {queue, demand}}
    end
  end
end
