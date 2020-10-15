defmodule Wumpex.Gateway.EventProducer do
  @moduledoc """
  This module handles the processing of events dispatched by the gateway.

  This is the first stage in processing events for a specific guild.
  The next step is caching of state (see the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#tracking-state))
  and finally the event will be released to event handlers.
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
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenStage
  def init(_options) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_demand(1, {queue, demand}) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        # We took an item off, so demand increased and decreased by 1.
        {:noreply, [event], {queue, demand}}

      {:empty, queue} ->
        # No queued events, we increase the demand by one.
        {:noreply, [], {queue, demand + 1}}
    end
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
end
