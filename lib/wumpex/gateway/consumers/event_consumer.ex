defmodule Wumpex.Gateway.Consumers.EventConsumer do
  use GenStage

  alias Wumpex.Gateway.EventProducer

  require Logger

  @type options :: [
          producer: GenServer.server(),
          guild: String.t() | nil,
          handler: [
            module: module(),
            selector: function() | nil,
            initial: [EventProducer.event()] | nil
          ]
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

  @impl GenStage
  def handle_events(events, _from, %{handler: handler, handler_state: handler_state} = state) do
    handler_state = Enum.reduce(events, handler_state, &handler.handle/2)

    {:noreply, [], %{state | handler_state: handler_state}}
  end

  # Get the selector when there's no guild to scope to.
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

    fn %{name: name, payload: payload} = event ->
      guild_id =
        case name do
          :GUILD_CREATE ->
            Map.get(payload, :id, nil)

          _name ->
            Map.get_lazy(payload, :guild_id, fn ->
              Map.get(payload, "guild_id")
            end)
        end

      guild_id == guild and selector.(event)
    end
  end
end
