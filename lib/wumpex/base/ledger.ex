defmodule Wumpex.Base.Ledger do
  @moduledoc """
  A facade module for a registry that is either local or distributed.
  Ledger accomplishes this by using either the built-in `Registry` module (when compiling for local registry), or [`:syn`](https://github.com/ostinelli/syn) (when compiling distributed).

  ## Motivation
  Wumpex uses registers internally, but the built in `Registry` is only local, so it can't be used in a distributed scenario
  and when working locally using [`:syn`](https://github.com/ostinelli/syn) for a registry would be total overkill.
  Ledger attempts to solve this problem by deciding at compile time which of the two libraries should be used, and conditionally compiles the module with only one of them active.

  ## Usage
  You can use the Ledger module by simply calling `use` with it, and passing whether it's a `:global` registry or not.
  When compiling a global registry, Ledger uses [`:syn`](https://github.com/ostinelli/syn) under the hood,
  so if you set the `:global` flag to true without [`:syn`](https://github.com/ostinelli/syn) installed it'll throw a compiler error.

  Defining a local registry (only accessible on the same node):
      defmodule LocalRegistry do
        use Wumpex.Base.Ledger, global: false
      end

  Defining a global registry (available on every node):
      defmodule GlobalRegistry do
        use Wumpex.Base.Ledger, global: true
      end

  ## Using in `:via`
  Because Ledger aims to provide maximal interchangeability between `Registry` and [`:syn`](https://github.com/ostinelli/syn),
  it also provides support for the `:via` registration (see [GenServer documentation](https://hexdocs.pm/elixir/GenServer.html#module-name-registration) on registering with `:via`).

  If you start a GenServer with the `:name` option to be `{:via, MyLedgerModule, "name"}` for example, the GenServer will automatically be registered in the `MyLedgerModule` registry.

  You can also pass in metadata using `{:via, MyLedgerModule, "name", "anything here"}` (metadata can be any type, not just strings).

  ## Limitations
  When using a local registry you can register the same name under multiple (local) registries, since they'll all be isolated.

  When using a global registry however, the names you register will be shared over all global registries, since they'll all use [`:syn`](https://github.com/ostinelli/syn) under the hood.
  """

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  defmacro __using__(options) when is_list(options) do
    # Get whether we're compiling a distributed or local Ledger.
    distributed? =
      Keyword.get_lazy(options, :global, fn ->
        Application.get_env(:wumpex, :distributed, false)
      end)

    # Ensure that :syn is loaded when we're compiling Ledger for distributed usage.
    if distributed? and Code.ensure_loaded?(:syn) == false do
      raise CompileError,
        file: __ENV__.file,
        line: __ENV__.line,
        description: "Compiling #{__MODULE__} in distributed mode, but Syn is not available."
    end

    quote do
      @doc false
      @spec child_spec(any()) :: Supervisor.child_spec()
      def child_spec(_opts \\ []) do
        unquote(generate_child_spec(distributed?))
      end

      @doc false
      @spec start_link(opts :: any()) :: term()
      def start_link(_opts \\ []) do
        unquote(generate_start_link(distributed?))
      end

      @doc """
      Looks up the `t:pid/0` with metadata for a given `name`.
      Returns `nil` if no entry could be found for the given name.

          iex> MyLedger.register("some-process", self(), "metadata")
          :yes

          iex> MyLedger.lookup("some-process")
          {pid, "metadata"}

      See `register/3` for setting metadata.
      """
      @spec lookup(name :: any()) :: {pid(), any()} | nil
      def lookup(name) do
        unquote(generate_lookup(distributed?))
      end

      @doc """
      Register a given `t:pid/0` under the given `:name` in the registry, optionally passing in metadata.
      """
      @spec register(name :: any(), pid :: pid(), metadata :: any()) :: :yes | :no
      def register(name, pid, metadata \\ nil), do: register_name({name, metadata}, pid)

      @doc false
      # GenServer :via interface
      @spec register_name(name :: any() | {any(), any()}, pid :: pid()) :: :yes | :no
      def register_name(name, pid) do
        unquote(generate_register_name(distributed?))
      end

      @doc false
      @spec unregister_name(name :: any()) :: :ok
      def unregister_name(name) do
        unquote(generate_unregister_name(distributed?))
      end

      @doc false
      @spec whereis_name(name :: any()) :: pid() | :undefined
      def whereis_name(name) do
        unquote(generate_whereis_name(distributed?))
      end
    end
  end

  # Generate the child_spec function for distributed Ledger.
  # Call start_link which does nothing.
  defp generate_child_spec(distributed?) when distributed? do
    quote do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, []}
      }
    end
  end

  # Generate the child_spec for local Ledger
  # Basically just setup a Registry instance.
  defp generate_child_spec(_distributed?) do
    quote do
      Registry.child_spec(
        name: __MODULE__,
        keys: :unique,
        partitions: System.schedulers_online()
      )
    end
  end

  # Generate the start_link method for distributed ledger.
  defp generate_start_link(distributed?) when distributed? do
    quote do
      Application.ensure_started(:syn)
      :ignore
    end
  end

  # Generate the start_link method for local ledger.
  defp generate_start_link(_distributed?) do
    quote do
      Registry.start_link(keys: :unique, name: __MODULE__, partitions: System.schedulers_online())
    end
  end

  # Generates the lookup function for distributed Ledger.
  defp generate_lookup(distributed?) when distributed? do
    quote do
      case :syn.whereis(name, :with_meta) do
        :undefined ->
          nil

        result ->
          result
      end
    end
  end

  # Generates the lookup function for the local Ledger.
  defp generate_lookup(_distributed?) do
    quote do
      case Registry.lookup(__MODULE__, name) do
        [] ->
          nil

        [result] ->
          result
      end
    end
  end

  # Generate the register_name function for distributed Ledger
  defp generate_register_name(distributed?) when distributed? do
    quote do
      case name do
        {name, meta} ->
          case :syn.register(name, pid, meta) do
            :ok ->
              :yes

            _error ->
              :no
          end

        name ->
          :syn.register_name(name, pid)
      end
    end
  end

  # Generate the register_name function for local Ledger
  defp generate_register_name(_distributed?) do
    quote do
      case name do
        {name, meta} ->
          Registry.register_name({__MODULE__, name, meta}, pid)

        name ->
          Registry.register_name({__MODULE__, name}, pid)
      end
    end
  end

  # Generate the unregister_name function for the distributed Ledger.
  defp generate_unregister_name(distributed?) when distributed? do
    quote do
      :syn.unregister_name(name)

      :ok
    end
  end

  # Generate the unregister_name function for the local Ledger.
  defp generate_unregister_name(_distributed?) do
    quote do
      Registry.unregister_name({__MODULE__, name})
    end
  end

  # Generate the whereis_name function for the distributed Ledger.
  defp generate_whereis_name(distributed?) when distributed? do
    quote do
      case name do
        {name, _metadata} ->
          :syn.whereis_name(name)

        name ->
          :syn.whereis_name(name)
      end
    end
  end

  # Generate the whereis_name function for the local Ledger.
  defp generate_whereis_name(_distributed?) do
    quote do
      case name do
        {name, _metadata} ->
          Registry.whereis_name({__MODULE__, name})

        name ->
          Registry.whereis_name({__MODULE__, name})
      end
    end
  end
end
