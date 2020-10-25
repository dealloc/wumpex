defmodule Wumpex.Bot do
  defmacro __using__(_options) do
    quote do
      Module.register_attribute(__MODULE__, :wumpex_handlers, accumulate: true)

      @before_compile Wumpex.Bot

      import Wumpex.Bot
    end
  end

  @callback init() :: term()

  @callback handle(event :: Wumpex.Gateway.EventProducer.event(), state :: term()) :: term()

  defmacro __before_compile__(env) do
    handlers = Module.get_attribute(env.module, :wumpex_handlers)

    quote generated: true do
      def child_spec(_options) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []}
        }
      end

      def start_link(_options \\ []) do
        Wumpex.Sharding.start_link([
          handlers: unquote(handlers)
        ])
      end
    end
  end

  defmacro event(module) do
    quote do
      @wumpex_handlers [handler: unquote(module)]
    end
  end
end
