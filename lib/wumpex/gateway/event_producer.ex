defmodule Wumpex.Gateway.EventProducer do
  @moduledoc """
  The first stage in processing events received from the `Wumpex.Gateway`.

  This module implements `GenStage` as a `:producer` and handles collecting events from the `Wumpex.Gateway` and buffering them if needed.
  Whenever consumers (event listeners) are ready to process events the `EventProducer` will dispatch them to the listeners.

  Events are not directly dispatched to event consumers, they are first sent to the `Wumpex.Gateway.Caching` layer to keep the state in sync.
  """

  use GenStage

  alias Wumpex.Gateway.Event

  require Logger

  @typedoc """
  The state of the producer.

  The first element of the tuple is an Erlang queue, the second item is an integer representing the pending demand.
  """
  @type state :: {:queue.queue(), non_neg_integer()}

  @doc """
  Dispatch an event to the given producer.

  This puts the event in the processing pipeline for caching and eventually handling.
  """
  @spec dispatch(producer :: pid(), event :: Event.t()) :: :ok
  def dispatch(producer, event) do
    send(producer, {:event, event})
  end

  @doc false
  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  @doc false
  @impl GenStage
  @spec init(term()) :: {:producer, state(), [GenStage.producer_option()]}
  def init(_options) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @doc false
  @impl GenStage
  @spec handle_demand(pos_integer(), state()) :: {:noreply, [Event.t()], state()}
  def handle_demand(incoming, {queue, demand}) do
    pop_events([], queue, demand + incoming)
  end

  # Called when a new event is published but there's no demand, we queue the event.
  @doc false
  @impl GenStage
  @spec handle_info({:event, Event.t()}, state()) :: {:noreply, [Event.t()], state()}
  def handle_info({:event, event}, {queue, 0}) do
    queue = :queue.in(event, queue)

    {:noreply, [], {queue, 0}}
  end

  # Called when a new event is published, and there's already demand for an event.
  @doc false
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
  @spec pop_events([Event.t()], :queue.queue(Event.t()), non_neg_integer()) ::
          {:noreply, [Event.t()], state()}
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
