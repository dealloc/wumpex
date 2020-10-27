defmodule Wumpex.Gateway.Consumers.GuildsConsumer do
  @moduledoc """
  A specialized event listener that checks for new guilds.

  Like `Wumpex.Gateway.Consumers.EventConsumer` this module subscribes to `Wumpex.Gateway.Caching` and listens for incoming events.
  The main difference is that instead of forwarding incoming events to a handler, it starts a new `EventConsumer` scoped to a guild whenever a new guild becomes available.

  This allows specifying a handler that should be instantiated for each guild that becomes available.
  """

  use GenStage

  alias Wumpex.Gateway.Consumers
  alias Wumpex.Gateway.EventProducer

  require Logger

  @typedoc """
  Represents the handler options for a handler that will be instantiated for each guild that becomes available.

  Contains the following fields:
  * `:module` - The module to which events of a guild will be sent.
  * `:selector` - If not nil, a selector function to filter incoming events (see `t:Wumpex.Gateway.Consumers.EventConsumer.options/0`).
  """
  @type guild_handler :: [
          module: module(),
          selector: function() | nil
        ]

  @typedoc """
  Represents the options that can be passed into `start_link/1`.

  Contains the following fields:
  * `:producer` - The producer to which the `GuildsConsumer` should subscribe to.
  * `:guild_handler` - The `t:guild_handler/0` to instantiate for each guild.
  """
  @type options :: [
          producer: GenServer.server(),
          guild_handler: guild_handler()
        ]

  @typedoc """
  Represents the process state.

  Contains the following fields:
  * `:guild_handler` - The `t:guild_handler/0` to instantiate for each guild.
  * `:producer` - The producer to which the `EventConsumer` should subscribe to.
  """
  @type state :: %{
          guild_handler: guild_handler(),
          producer: GenServer.server()
        }

  @doc """
  Start a new `GuildsConsumer` linked to the current process.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    GenStage.start_link(__MODULE__, options)
  end

  @doc false
  @impl GenStage
  @spec init(options()) :: {:consumer, state(), [GenStage.consumer_option()]}
  def init(producer: producer, guild_handler: guild_handler) do
    # Filter to only receive GUILD_CREATE events.
    selector = &(Map.get(&1, :name, nil) == :GUILD_CREATE)

    {:consumer, %{guild_handler: guild_handler, producer: producer},
     subscribe_to: [
       {producer, max_demand: 1, min_demand: 0, selector: selector}
     ]}
  end

  @doc false
  @impl GenStage
  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(&1, state))

    {:noreply, [], state}
  end

  # Handles incoming :GUILD_CREATE events and starts new EventConsumer instances for each.
  @spec handle_event(EventProducer.event(), state()) :: DynamicSupervisor.on_start_child()
  defp handle_event(%{name: :GUILD_CREATE, payload: %{id: guild}} = event, %{
        guild_handler: guild_handler,
        producer: producer
      }) do
    module = Keyword.fetch!(guild_handler, :module)
    filter = Keyword.get(guild_handler, :filter)

    Logger.info("Starting new #{inspect(module)} handler for #{guild}")
    {:ok, _consumer} = Consumers.start_consumer(producer,
      module: module,
      filter: filter,
      guild: guild,
      initial: [event]
    )
  end
end
