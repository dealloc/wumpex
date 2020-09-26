defmodule Wumpex.Base.Ledger do
  defmacro __using__(options) when is_list(options) do
    # Get whether we're compiling a distributed or local Ledger.
    distributed? = Keyword.fetch!(options, :global)
    # Which registry to use (:syn for distributed, Registry for local).
    registry = base_module(distributed?)

    # Ensure that :syn is loaded when we're compiling Ledger for distributed usage.
    if distributed? and Code.ensure_loaded?(:syn) == false do
      raise CompileError,
        file: __ENV__.file,
        line: __ENV__.line,
        description: "Compiling #{__MODULE__} in distributed mode, but Syn is not available."
    end

    quote do
      # TODO: defdelegate might break the facade that local and distributed are the same.
      # Since Registry requires a different calling convention than :syn.
      defdelegate register_name(name, pid), to: unquote(registry)
      defdelegate unregister_name(name), to: unquote(registry)
      defdelegate whereis_name(name), to: unquote(registry)

      @doc false
      def child_spec(_opts \\ []) do
        unquote(generate_child_spec(distributed?))
      end

      @doc false
      @spec start_link(opts :: any()) :: :ignore
      def start_link(_opts \\ []) do
        :ignore
      end

      @doc """
      Looks up the `t:pid/0` for a given `name`.
      Returns `nil` if no pid could be found for the given name.
      """
      @spec lookup(name :: any()) :: pid() | nil
      def lookup(name) do
        unquote(generate_lookup(distributed?))
      end

      @doc """
      Shorthand for `register_name(name, self())`.
      """
      def register(name), do: register_name(name, self())
    end
  end

  # Get the base module to generate defdelegates to.
  defp base_module(distributed?) when distributed?, do: :syn
  defp base_module(_distributed?), do: Registry

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

  # Generates the lookup function for distributed Ledger.
  defp generate_lookup(distributed?) when distributed? do
    quote do
      case :syn.whereis(name) do
        :undefined ->
          nil

        pid ->
          pid
      end
    end
  end

  # Generates the lookup function for the local Ledger.
  defp generate_lookup(_distributed?) do
    quote do
      case Registry.lookup(__MODULE__, name) do
        [] ->
          nil

        [{pid, _value}] ->
          pid
      end
    end
  end
end
