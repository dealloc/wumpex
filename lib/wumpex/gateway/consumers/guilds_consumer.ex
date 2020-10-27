defmodule Wumpex.Gateway.Consumers.GuildsConsumer do
  use GenStage

  alias Wumpex.Gateway.Consumers

  require Logger

  @type guild_handler :: [
          module: module(),
          selector: function() | nil
        ]

  @type options :: [
          producer: GenServer.server(),
          guild_handler: guild_handler()
        ]

  @type state :: %{
          guild_handler: guild_handler(),
          producer: GenServer.server()
        }

  @doc false
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, options)
  end

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

  @impl GenStage
  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(&1, state))

    {:noreply, [], state}
  end

  def handle_event(%{name: :GUILD_CREATE, payload: %{id: guild}} = event, %{
        guild_handler: guild_handler,
        producer: producer
      }) do
    module = Keyword.fetch!(guild_handler, :module)
    filter = Keyword.get(guild_handler, :filter)

    Logger.info("Starting new #{inspect(module)} handler for #{guild}")
    Consumers.start_consumer(producer,
      module: module,
      filter: filter,
      guild: guild,
      initial: [event]
    )
  end
end
