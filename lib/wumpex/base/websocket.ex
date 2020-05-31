defmodule Wumpex.Base.Websocket do
  @moduledoc """
  Provides a generic component for opening a websocket connection and interacting with it.

  This module is designed to be used as part of a supervision tree:

      {Wumpex.Base.Websocket, url: "wss://some.server", worker: MyApplication.WebsocketHandler}

  This will start a websocket connection (secured with SSL) to *some.server* and send incoming events to a module called `MyApplication.WebsocketHandler`.

  ## Options
  The websocket supports the following options (also see `t:options/0`):
    * `:url` - The URL to which the websocket should connect.
    * `:name` - The name under which the websocket process should register itself (this defaults to `{:local, __MODULE__}`, see `t:GenServer.name/0` for more information).
    * `:worker` - The worker to which incoming events will be dispatched (see `t:GenServer.server/0` for more information).

  ## Workers
  The websocket module dispatches all of it's incoming events (internally called *frames*) to the worker module for processing using `GenServer.cast/2`.

  Since this module is designed to be entirely generic in terms of incoming data, it passes it's frames on without any transformation.
  The library used under the hood (`:websocket_client`) defines 2 possible incoming data formats (see `t:worker_event/0`):
    * `{:text, content}` - Passed when the incoming frame contains textual data.
    * `{:binary, content}` - Passed when the incoming frame contains aribtrary binary data.

  An example worker could look like this:

      defmodule MyHandler do
        use GenServer

        require Logger

        def start_link(_) do
          GenServer.start_link(__MODULE__, [])
        end

        def init(_) do
          {:ok, []}
        end

        def handle_cast({{:text, _payload}, websocket}, state) do
          send(websocket, {:send, {:text, "Reply"}})

          {:noreply, state}
        end
      end
  """

  @behaviour :websocket_client

  require Logger

  @typedoc """
  The options that can be passed into the `child_spec/1` and `start_link/1` method.
    * `:url` - The URL to which the websocket should connect.
    * `:name` - The name under which the websocket process should register itself (this defaults to `{:local, __MODULE__}`, see `t:GenServer.name/0` for more information).
    * `:worker` - The worker to which incoming events will be dispatched (see `t:GenServer.server/0` for more information).
  """
  @type options :: [
          # The URL to which the websocket should connect.
          url: String.t() | binary(),
          # The name under which to register the process.
          name: GenServer.name() | nil,
          # The worker which handles incoming events.
          worker: GenServer.server()
        ]

  @typedoc """
  The state of the websocket process.
    * `:worker` - The worker to which to send incoming events using `GenServer.cast/2`.
    * `:url` - The URL to which the websocket is connected (this is mainly for diagnostics).
  """
  @type state :: %{
          # See options().worker
          worker: GenServer.server(),
          # The URL to which we're connected
          url: String.t()
        }

  @typedoc """
  The type of events that are sent to the worker.
  """
  @type worker_event :: {{:text | :binary, binary()}, pid()}

  @doc """
  Instructs the Websocket to close itself with the given `reason`.

      Websocket.close(socket, :error)
  """
  @spec close(websocket :: pid(), reason :: term()) :: term()
  def close(websocket, reason) when is_pid(websocket) and is_atom(reason) do
    send(websocket, {:close, reason})
  end

  @doc """
  Instructs the Websocket to send a given `message`.

  You can pass whether to use binary or text mode using the `options`:
      # Will use text mode
      Websocket.send(socket, "Hello world", mode: :text)

      # Will use binary mode
      Websocket.send(socket, "Hello world", mode: :binary)
  """
  @spec send(websocket :: pid(), message :: any(), options :: keyword(atom())) :: term()
  def send(websocket, message, mode: mode)
      when is_pid(websocket) and is_binary(message) and is_atom(mode) do
    send(websocket, {:send, {mode, message}})
  end

  # Allows using this module as child of a supervisor.
  # See https://hexdocs.pm/elixir/Supervisor.html#module-child_spec-1 for more information.
  @doc false
  @spec child_spec(options()) :: Supervisor.child_spec()
  def child_spec(init_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_args]},
      type: :worker
    }
  end

  # Start the websocket connection as a linked process.
  @doc false
  @spec start_link(options()) :: :ignore | {:error, any()} | {:ok, pid}
  def start_link(options) do
    url = Keyword.fetch!(options, :url)
    name = Keyword.get(options, :name, {:local, __MODULE__})

    Logger.debug("Connecting to #{url}")
    :websocket_client.start_link(name, url, __MODULE__, options, [])
  end

  # Initialize the state and re-connection strategy of the websocket.
  @doc false
  @impl :websocket_client
  @spec init(options()) :: {:once, state()}
  def init(options) do
    url = Keyword.get(options, :url)
    worker = Keyword.fetch!(options, :worker)

    {:once, %{worker: worker, url: url}}
  end

  # Callback for when the websocket connects.
  @doc false
  @impl :websocket_client
  def onconnect(_conn, %{url: url} = state) do
    Logger.debug("Connected to #{url}!")

    {:ok, state}
  end

  # Callback for then the websocket disconnects.
  # This doesn't seem to properly get called unfortunately.
  @doc false
  @impl :websocket_client
  def ondisconnect(_conn, %{url: url} = state) do
    Logger.warn("Disconnected from #{url}, attempting to reconnect!")

    {:reconnect, state}
  end

  # Called when we receive incoming frames.
  @doc false
  @impl :websocket_client
  def websocket_handle(frame, _conn, %{worker: worker} = state) do
    GenServer.cast(worker, {frame, self()})

    {:ok, state}
  end

  # Handles incoming erlang message requesting to send a frame on the websocket.
  @doc false
  @impl :websocket_client
  @spec websocket_info({:send, :websocket_client.frame()}, :websocket_req.req(), state()) ::
          {:reply, :websocket_client.frame(), state()}
  def websocket_info({:send, frame}, _conn, state) do
    {:reply, frame, state}
  end

  # Unknown erlang messages!
  @doc false
  @impl :websocket_client
  def websocket_info(msg, _conn, state) do
    Logger.warn("Unknown command received on Websocket: #{inspect(msg)}")

    {:ok, state}
  end

  # Called when the process terminates.
  @doc false
  @impl :websocket_client
  def websocket_terminate(reason, _conn, _state) do
    Logger.error("Socket terminating: #{inspect(reason)}")

    :ok
  end
end
