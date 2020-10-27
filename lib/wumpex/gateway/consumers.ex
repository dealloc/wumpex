defmodule Wumpex.Gateway.Consumers do
  alias Wumpex.Gateway.Consumers.EventConsumer
  alias Wumpex.Gateway.Consumers.GuildsConsumer
  alias Wumpex.Gateway.EventProducer

  require Logger

  @typedoc """
  Represents the configuration for an event handler.

  An event handler subscribes to events on the gateway, the `:filter` option can be used to subscribe to a limited number of events.
  The `:guild` option can be used to have an instance of the handler for each guild specific event.

  Contains the following fields:
  * `:module` - The module that will receive the incoming events.
  * `:filter` - (optional) A function that takes in an event and returns true or false whether to accept this event or not
  * `:guild` - (optional) If set to true this handler will be instantiated for each guild and receive events for a specific guild.
  * `:initial` - (optional) A list of events that will be simulated on the handler upon startup.
  """
  @type handler_options :: [
          {:module, module()}
          | {:filter, function()}
          | {:guild, boolean() | String.t()}
          | {:initial, [EventProducer.event()]}
        ]

  # Starts the approperiate type of consumer for this handler configuration.
  @spec start_consumer(producer :: GenServer.server(), handler :: handler_options()) ::
          DynamicSupervisor.on_start_child()
  def start_consumer(producer, handler) do
    module = Keyword.fetch!(handler, :module)
    filter = Keyword.get(handler, :filter)
    guild = Keyword.get(handler, :guild, false)
    initial = Keyword.get(handler, :initial, [])

    start_consumer(producer, module, filter, guild, initial)
  end

  @spec start_consumer(
          producer :: GenServer.server(),
          module :: module(),
          filter :: function() | nil,
          guild :: boolean() | String.t(),
          initial :: [EventProducer.event()]
        ) :: DynamicSupervisor.on_start_child()
  # Start a GuildsConsumer, which listens for GUILD_CREATE events and spawns new listeners scoped to that guild.
  defp start_consumer(producer, module, filter, true, []) do
    DynamicSupervisor.start_child(
      Wumpex.GatewayListenerSupervisor,
      {GuildsConsumer,
       [
         producer: producer,
         guild_handler: [
           module: module,
           selector: filter
         ]
       ]}
    )
  end

  # Handles starting consumers for regular events (not scoped to a specific guild).
  defp start_consumer(producer, module, filter, false, initial) do
    DynamicSupervisor.start_child(
      Wumpex.GatewayListenerSupervisor,
      {EventConsumer,
       [
         producer: producer,
         guild: nil,
         handler: [
           module: module,
           selector: filter,
           initial: initial
         ]
       ]}
    )
  end

  # Handles starting consumers for regular events (scoped to a specific guild).
  defp start_consumer(producer, module, filter, guild, initial) do
    DynamicSupervisor.start_child(
      Wumpex.GatewayListenerSupervisor,
      {EventConsumer,
       [
         producer: producer,
         guild: guild,
         handler: [
           module: module,
           selector: filter,
           initial: initial
         ]
       ]}
    )
  end
end
