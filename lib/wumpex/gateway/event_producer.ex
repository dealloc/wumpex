defmodule Wumpex.Gateway.EventProducer do
  use GenStage

  require Logger

  @typedoc """
  The state of the producer.

  The first element of the tuple is an Erlang queue, the second item is an integer representing the pending demand.
  """
  @type state :: {:queue.queue(), non_neg_integer()}

  @typedoc """
  Represents an event that will be dispatched from the gateway to consumers.

  Contains the following fields:
  * `:shard` - A `t:Wumpex.shard/0` representing the shard from which the event originates.
  * `:name` - An atom with the name of the dispatched event.
  * `:payload` - The event payload in the form of a map.
  * `:sequence` - The sequence number of the event, can be used to track the same event across handlers.
  """
  @type event :: %{
    shard: Wumpex.shard(),
    name: atom(),
    payload: map(),
    sequence: non_neg_integer()
  }

  @doc """
  Dispatch an event to the given producer.

  This puts the event in the processing pipeline for caching and eventually handling.
  """
  @spec dispatch(producer :: pid(), event :: event()) :: :ok
  def dispatch(producer, event) do
    send(producer, {:event, event})
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
  @spec handle_info({:event, event()}, state()) :: {:noreply, [event()], state()}
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
