defmodule Wumpex.Gateway.Consumers.EventConsumer do
  use GenStage

  alias Wumpex.Gateway.Consumers

  require Logger

  @type options :: [
          producer: GenServer.server(),
          handler: Consumers.handler_options()
        ]

  @type state :: %{
          handler: module(),
          handler_state: term()
        }

  @doc false
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, options)
  end

  @impl GenStage
  @spec init(options()) :: {:consumer, state(), [GenStage.consumer_option()]}
  def init(producer: producer, handler: [handler: handler]) do
    handler_state = handler.init()

    {:consumer, %{handler: handler, handler_state: handler_state},
     subscribe_to: [
       {producer, max_demand: 1, min_demand: 0}
     ]}
  end

  @impl GenStage
  def handle_events(events, _from, %{handler: handler, handler_state: handler_state} = state) do
    handler_state = Enum.reduce(events, handler_state, &handler.handle/2)

    {:noreply, [], %{state | handler_state: handler_state}}
  end
end
