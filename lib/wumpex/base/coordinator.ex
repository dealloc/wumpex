defmodule Wumpex.Base.Coordinator do
  @moduledoc """
  This module allows a module to act as both a `Registry` and a `DynamicSupervisor`.

  It does so by implementing a `DynamicSupervisor` and exposing a `register/1` function.
  Child processes can then be started in the `DynamicSupervisor` and call the `register` method in their `init` method.

  Coordinators can then broadcast to all children for a given key using the `broadcast` method.

  ## Example

      defmodule ExampleCoordinator do
        use Wumpex.Base.Coordinator

        def start_child(example_sup, key) do
          DynamicSupervisor.start_child(example_sup, {ExampleChild, key: key})
        end
      end

  And then in the child module:

      defmodule ExampleChild do
        use GenServer

        alias Wumpex.Gateway.Guild.Coordinator

        @spec start_link(options :: keyword()) :: GenServer.on_start()
        def start_link(key: key) do
          GenServer.start_link(__MODULE__, key: key)
        end

        @impl GenServer
        def init(key: key) do
          Coordinator.register(key)

          {:ok, []}
        end
      end

  Finally make sure to start the registry in your application supervision tree:

      {Registry, keys: :duplicate, name: ExampleCoordinator, partitions: System.schedulers_online()}

  Once you call the `start_child` method a new child will be started (and supervised!).
  You can start multiple children with the same key, you can call the `broadcast` method to dispatch to all children listening on the same key.
  """

  @doc """
  Registers the current pid in the registry.

  Generally you'll call this in the `init/1` method.
  """
  @callback register(key :: any()) :: {:ok, pid} | {:error, {:already_registered, pid}}

  @doc """
  Broadcast an `event` to all children registered under a given `key`.
  """
  @callback broadcast(key :: any(), event :: any()) :: :ok

  defmacro __using__(_opts) do
    quote do
      use DynamicSupervisor

      @behaviour Wumpex.Base.Coordinator

      @spec start_link(options :: keyword()) :: Supervisor.on_start()
      def start_link(init_args) do
        DynamicSupervisor.start_link(__MODULE__, init_args)
      end

      @impl DynamicSupervisor
      def init(_init_args), do: DynamicSupervisor.init(strategy: :one_for_one)

      @impl Wumpex.Base.Coordinator
      def register(key) do
        Registry.register(__MODULE__, key, nil)
      end

      @impl Wumpex.Base.Coordinator
      def broadcast(key, event) do
        for {child, _} <- Registry.lookup(__MODULE__, key) do
          send(child, event)
        end

        :ok
      end
    end
  end
end
