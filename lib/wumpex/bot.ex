defmodule Wumpex.Bot do
  @moduledoc """
  Base module for defining a bot.

  The `Wumpex.Bot` module provides helpers to define event listeners to react to incoming events from Discord.
  """

  @doc false
  @spec __using__(any()) :: tuple()
  defmacro __using__(_options) do
    quote generated: true do
      Module.register_attribute(__MODULE__, :wumpex_handlers, accumulate: true)

      @before_compile Wumpex.Bot

      import Wumpex.Bot
    end
  end

  @doc false
  @spec __before_compile__(Macro.Env.t()) :: tuple()
  defmacro __before_compile__(env) do
    handlers = Module.get_attribute(env.module, :wumpex_handlers)

    quote generated: true, location: :keep do
      @spec child_spec(any()) :: Supervisor.child_spec()
      def child_spec(_options) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []}
        }
      end

      @spec start_link(any()) :: GenServer.on_start()
      def start_link(_options \\ []) do
        Wumpex.Sharding.start_link(handlers: unquote(handlers))
      end
    end
  end

  @doc """
  Defines a new event listener for gateway events.
  """
  @spec event(module()) :: tuple()
  defmacro event(module) do
    quote do
      @wumpex_handlers [module: unquote(module), guild: false]
    end
  end

  @doc """
  Defines a new event listener for gateway events, scoped per guild.
  """
  @spec guild(module()) :: tuple()
  defmacro guild(module) do
    quote do
      @wumpex_handlers [module: unquote(module), guild: true]
    end
  end
end
