defmodule Wumpex.Gateway.Consumers.EventConsumer do
  @moduledoc """
  Receives events from a `Wumpex.Gateway`.

  The `EventConsumer` provides a convenience layer for subscribing to events from the event processing stages (see `Wumpex.Gateway.EventProducer` and `Wumpex.Gateway.Caching`).
  It implements `GenStage` as a `:consumer` and handles subscribing to the producer.
  It also takes care of filtering incoming events (through the `:guild` and `:selector` option) and allows specifying `:initial` events to replay when the listener starts up.

  EventConsumers are generally started using `Wumpex.Gateway.Consumers.start_consumer/2`, but you can start one directly by calling `start_link/1`.
  """

  use GenStage

  alias Wumpex.Gateway.Event

  require Logger

  @typedoc """
  Represents the options that have to be passed into `start_link/1`.

  Contains the following fields:
  * `:producer` - The producer to which the `EventConsumer` should subscribe to.
  * `:guild` - If not nil, all incoming events will be filtered to only include events from this guild.
  * `:handler` - Describes the handler for incoming events.
    * `:module` - The module that will receive incoming events.
    * `:selector` - If not nil, a function that receives an event and returns true or false to indicate if the event should be processed.
    * `:initial` - If not nil, a list of events that will be replayed on the handler upon startup.
  """
  @type options :: [
          producer: GenServer.server(),
          guild: String.t() | nil,
          handler: [
            module: module(),
            selector: function() | nil,
            initial: [Event.t()] | nil
          ]
        ]

  @typedoc """
  Represents the process state.

  Contains the following fields:
  * `:handler` - The module to which incoming events will be dispatched.
  * `:handler_state` - The state of the `:handler` module, generated from the `:handler` module's init function.
  """
  @type state :: %{
          handler: module(),
          handler_state: term()
        }

  @doc """
  Start a new `EventConsumer` linked to the current process.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenStage.start_link(__MODULE__, options)
  end

  @doc false
  @impl GenStage
  @spec init(options()) :: {:consumer, state(), [GenStage.consumer_option()]}
  def init(producer: producer, guild: guild, handler: handler_options) do
    handler = Keyword.fetch!(handler_options, :module)
    selector = get_selector(guild, handler_options)
    initial = Keyword.get(handler_options, :initial, [])

    # Calculate initial handler state and replay all initial events.
    handler_state = Enum.reduce(initial, handler.init(), &handler.handle/2)

    {:consumer, %{handler: handler, handler_state: handler_state},
     subscribe_to: [
       {producer, max_demand: 1, min_demand: 0, selector: selector}
     ]}
  end

  @doc false
  @impl GenStage
  @spec handle_events([Event.t()], GenStage.from(), state()) :: {:noreply, [], state()}
  def handle_events(events, _from, %{handler: handler, handler_state: handler_state} = state) do
    handler_state = Enum.reduce(events, handler_state, &handler.handle/2)

    {:noreply, [], %{state | handler_state: handler_state}}
  end

  # Get the selector when there's no guild to scope to.
  @spec get_selector(guild :: nil | non_neg_integer(), handler_options :: keyword()) ::
          function() | nil
  defp get_selector(nil, handler_options), do: Keyword.get(handler_options, :selector, nil)

  # Get the selector but only run if the guild matches since a guild to match on was passed.
  defp get_selector(guild, handler_options) do
    selector =
      case Keyword.get(handler_options, :selector) do
        nil ->
          fn _event -> true end

        selector ->
          selector
      end

    fn event = event ->
      Event.guild(event) == guild and selector.(event)
    end
  end
end
