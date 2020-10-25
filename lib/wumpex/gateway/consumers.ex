defmodule Wumpex.Gateway.Consumers do

  alias Wumpex.Gateway.Consumers.EventConsumer

  @typedoc """
  Represents the configuration for an event handler.

  An event handler subscribes to events on the gateway, the `:filter` option can be used to subscribe to a limited number of events.
  The `:guild` option can be used to have an instance of the handler for each guild specific event.

  Contains the following fields:
  * `:handler` - The module that will receive the incoming events.
  * `:filter` - (optional) A function that takes in an event and returns true or false whether to accept this event or not
  * `:guild` - (optional) If set to true this handler will be instantiated for each guild and receive events for a specific guild.
  """
  @type handler_options :: [
          {:handler, module()}
          | {:filter, function()}
          | {:guild, boolean()}
        ]

  # Starts the approperiate type of consumer for this handler configuration.
  @spec start_consumer(producer :: GenServer.server(), handler :: handler_options()) ::
          DynamicSupervisor.on_start_child()
  def start_consumer(producer, handler) do
    # Currently only have EventConsumer, but we're going to add more listener types (like guild specific listeners)
    DynamicSupervisor.start_child(
      Wumpex.GatewayListenerSupervisor,
      {EventConsumer,
       [
         producer: producer,
         handler: handler
       ]}
    )
  end
end
