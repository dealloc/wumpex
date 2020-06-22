defmodule Wumpex.Base.Coordinator do
  @moduledoc """
  This module allows a module to act as both a `Registry` and a `DynamicSupervisor`.
  """

  defmacro __using__(_opts) do
    quote do
      use DynamicSupervisor

      @spec start_link(options :: keyword()) :: Supervisor.on_start()
      def start_link(init_args) do
        DynamicSupervisor.start_link(__MODULE__, init_args)
      end

      @impl DynamicSupervisor
      def init(_init_args), do: DynamicSupervisor.init(strategy: :one_for_one)

      @doc """
      Registers the current pid in the registry.

      Generally you'll call this in the `init/1` method.
      """
      @spec register(key :: any()) :: {:ok, pid} | {:error, {:already_registered, pid}}
      def register(key) do
        Registry.register(__MODULE__, key, nil)
      end

      @doc """
      Broadcast an `event` to all children registered under a given `key`.
      """
      @spec broadcast(key :: any(), event :: any()) :: :ok
      def broadcast(key, event) do
        for {child, _} <- Registry.lookup(__MODULE__, key) do
          send(child, event)
        end

        :ok
      end
    end
  end
end
