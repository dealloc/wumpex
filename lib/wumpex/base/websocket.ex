defmodule Wumpex.Base.Websocket do
  # credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
  @moduledoc """
  A behaviour module for implementing the client of a websocket connection.

  A Websocket is a process like a common `GenServer` but handles the opening of the websocket transparently for you.
  All extensions made to the regular `GenServer` have been designed to closely match the behaviour of a regular `GenServer`.

  For example the `handle_frame` callback has very similiar return values to the `handle_call` callback of the GenServer.

  ## Options
  The Websocket requires a few options to be passed in the `start_link` method:
  * `:host` - the hostname (ex: `"gateway.discord.gg"`).
  * `:port` - the port to connect to (usually `80` for unencrypted and `443` for encrypted connections).
  * `:path` - the path to which the websocket will connect (ex: `"/?v=8"`) and can (but doesn't have to) contain a query string.
  * `:timeout` is a `t:timeout/0` used to determine how long to wait for connecting and upgrading.

  See `t:options/0` for more information.

  ## Example

  A module implementing the behaviour will be able to respond to incoming messages by implementing `handle_frame`:

      defmodule ExampleWebsocket do
        use Wumpex.Base.Websocket

        require Logger

        def on_connected(_options) do
          Logger.info("Connected!")
        end

        def handle_frame({:text, message}, state) do
          Logger.info("Received message")

          {:noreply, state}
        end
      end
  """

  require Logger

  @typedoc """
  Represents a single websocket frame that can be sent or received over the websocket.

  There's three supported frames:
  * `{:text, message}` - Used to send/receive textual data.
  * `{:binary, message}` - Used to send/receive binary data (like [ETF](https://erlang.org/doc/apps/erts/erl_ext_dist.html)).
  * `:close` or `{:close, status, reason}` - Signals that the websocket will be closed (to the receiving side), optionall you can pass in a status code and a reason.

  `:ping` and `:pong` frames are handled internally and not exposed.
  """
  @type frame ::
          {:text, String.t()}
          | {:binary, iodata()}
          | {:close, non_neg_integer(), iodata()}
          | :close

  @typedoc """
  The options that are required to be passed to the websocket on startup.

  `host` is the hostname (ex: `"gateway.discord.gg"`),
  `port` is the port to connect to (usually `80` for unencrypted and `443` for encrypted connections),
  `path` is the path to which the websocket will connect (ex: `"/?v=8"`) and can (but doesn't have to) contain a query string
  and finally `timeout` is a `t:timeout/0` used to determine how long to wait for connecting and upgrading.

  All options are required to be passed in.
  """
  @type options :: [
          host: String.t(),
          port: non_neg_integer(),
          path: String.t(),
          timeout: timeout()
        ]

  @typedoc """
  Reconnection strategy to use when returning from `on_disconnected/1`.

  There are currently 3 reconnection strategies supported:
  * `:stop` - No reconnection, this will gracefully shut down the server.
  * `:retry` - Immediately attempt to reconnect.
  * `{:retry, delay}` - Wait for `delay` milliseconds, then attempt to reconnect.

  Note that when using the delayed reconnect, the server will block and not process any messages until reconnection is complete.
  This is done to prevent receiving messages in the server when it is in a disconnected state.
  """
  @type reconnect_strategy :: :stop | :retry | {:retry, non_neg_integer()}

  @doc """
  Invoked when the websocket connects to the server.

  This method is invoked the first time the websocket connects.
  This method can be compared with the `init/1` method of the `GenServer`, and is used to set the state of the process.

  It receives the options passed to `start_link`

  The returned value will be used as the process state.
  """
  @callback on_connected(options :: keyword()) :: term()

  @doc """
  Called when the socket connection closes.

  `state` is the current process state,
  and the return value if this function is a tuple with the first element being the new process state and the second the `t:reconnect_strategy/0` to use.

  See `t:reconnect_strategy/0` for more information.
  """
  @callback on_disconnected(state :: term()) :: {term(), reconnect_strategy()}

  @doc """
  Called when the socket is reconnected.

  This function takes the current state and returns the new state for the process.
  """
  @callback on_reconnected(state :: term()) :: term()

  @doc """
  Invoked to handle incoming frames from the websocket connection.

  `frame` is the `t:frame/0` send by the server this websocket is connected to and `state` is the current state of the process.

  Returning `{:reply, frame, new_state}` will dispatch `frame` on the websocket and set `new_state` as the state of the process,
  while returning `{:noreply, new_state}` will not send any frames and set `new_state` as the new state of the process.

  You can also use the `:reply` and `:noreply` returns with an additional `t:timeout/0` parameter,
  which behaves the same but will also set a timeout (See [GenServer timeout](https://hexdocs.pm/elixir/GenServer.html#module-timeouts) section for more information).

  You can also reply with `{:stop, new_state}` to gracefully close the connection (after sending a close frame to the server) and terminate the process,
  or `{:stop, close_reason, new_state}` to send a status and reason along in the close frame that's being sent to the server.

  This callback and it's return types have intentionally been designed to be similiar to those of [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3),
  with the exception of the hibernate options, which is intentional.
  """
  @callback handle_frame(frame :: frame(), state :: term()) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout()}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout()}
              | {:stop, new_state}
              | {:stop, close_reason, new_state}
            when reply: frame(), new_state: term(), close_reason: {non_neg_integer(), iodata()}

  @optional_callbacks on_disconnected: 1, on_reconnected: 1

  @doc false
  defmacro __using__(_options) do
    quote location: :keep, generated: true do
      use GenServer, restart: :transient

      alias Wumpex.Base.Websocket

      require Logger

      @behaviour Websocket
      @before_compile Websocket

      @type frame_or_frames :: Websocket.frame() | [Websocket.frame()]

      @doc false
      @impl GenServer
      @spec init(options :: keyword()) :: {:ok, term()}
      def init(options) do
        host = Keyword.fetch!(options, :host)
        port = Keyword.fetch!(options, :port)
        path = Keyword.fetch!(options, :path)
        timeout = Keyword.fetch!(options, :timeout)
        Logger.metadata(url: "#{host}:#{port}#{path}")
        conn = connect_websocket(host, port, path, timeout)

        state = on_connected(options)
        {:ok, state}
      end

      @impl GenServer
      def format_status(_options, [dict, state]) do
        websocket = Keyword.get(dict, :"$websocket_metadata")

        [data: [Websocket: websocket]]
      end

      @doc false
      @impl GenServer
      # Handles incoming messages from the Gun websocket and dispatch them to the worker.
      def handle_info({:gun_ws, _conn, _stream, frame}, state) do
        case handle_frame(frame, state) do
          {:reply, reply, new_state} ->
            send_frame(reply)
            {:noreply, new_state}

          {:reply, reply, new_state, timeout} ->
            send_frame(reply)
            {:noreply, new_state, timeout}

          {:noreply, new_state} ->
            {:noreply, new_state}

          {:noreply, new_state, timeout} ->
            {:noreply, new_state, timeout}

          {:stop, new_state} ->
            send_frame(:close)
            {:noreply, new_state}

          {:stop, {code, reason}, new_state} ->
            send_frame({:close, code, reason})
            {:noreply, new_state}
        end
      end

      @doc false
      @impl GenServer
      def handle_info({:gun_down, _conn, _protcol, reason, _streams, _more_streams}, state) do
        Logger.debug("Connection lost, reason: #{inspect(reason)}")

        case on_disconnected(state) do
          {:stop, state} ->
            {:stop, :normal, state}

          {:retry, state} ->
            [host: host, port: port, path: path, timeout: timeout] =
              Process.get(:"$websocket_metadata")

            connect_websocket(host, port, path, timeout)

            state = on_reconnected(state)

            {:noreply, state}

          {{:retry, delay}, state} ->
            Process.sleep(delay)

            [host: host, port: port, path: path, timeout: timeout] =
              Process.get(:"$websocket_metadata")

            connect_websocket(host, port, path, timeout)

            state = on_reconnected(state)

            {:noreply, state}
        end
      end

      @doc false
      @impl GenServer
      def handle_call({:send, frame_or_frames}, _from, state) do
        {:reply, send_frame(frame_or_frames), state}
      end

      defp connect_websocket(host, port, path, timeout) do
        Logger.debug("Connecting to #{host}:#{port}#{path}...")
        # We should probably pass in :retry_fun, allowing to tweak the reconnect policy.
        {:ok, conn} = :gun.open(:binary.bin_to_list(host), port, %{protocols: [:http]})
        {:ok, :http} = :gun.await_up(conn, timeout)
        stream = :gun.ws_upgrade(conn, path)

        # :gun.wait does not support :gun_upgrade etc.
        receive do
          {:gun_upgrade, ^conn, ^stream, [<<"websocket">>], _headers} ->
            Logger.info("Connected to #{host}!")

          {:gun_response, ^conn, _undocumented, _another_undocumented, status, headers} ->
            Logger.error("Failed to connect to #{host}: Received #{inspect(status)}")
            exit({:error, status, headers})

          {:gun_error, ^conn, ^stream, reason} ->
            Logger.error("Failed to connect to #{host}: #{inspect(reason)}")
            exit({:error, reason})
        after
          timeout ->
            Logger.error(
              "Failed to connect to #{host}: Did not connect within #{inspect(timeout)}"
            )

            exit({:error, :timeout})
        end

        # Since the implementing module controls state, we put the information in the process dictionary.
        # I'm open to suggestions on how to improve this.

        # metadata used for reconnecting
        Process.put(:"$websocket_metadata",
          host: host,
          port: port,
          path: path,
          timeout: timeout
        )

        # metadata used for dispatching messages to the websocket
        Process.put(:"$websocket", conn)
        conn
      end

      @impl Wumpex.Base.Websocket
      def on_disconnected(state) do
        {:stop, state}
      end

      @impl Wumpex.Base.Websocket
      def on_reconnected(state) do
        state
      end

      @spec send_frame(frame_or_frames()) :: :ok
      defp send_frame(frame_or_frames) do
        conn = Process.get(:"$websocket", nil)

        :gun.ws_send(conn, frame_or_frames)
      end

      defoverridable on_disconnected: 1, on_reconnected: 1, format_status: 2
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:handle_frame, 2}) do
      raise CompileError,
        description: """
        The module #{env.module} does not implement the handle_frame/2 method!

        You can copy paste a default implementation below:
          def handle_frame(_frame, state) do
            {:noreply, state}
          end
        """
    end

    unless Module.defines?(env.module, {:on_connected, 1}) do
      raise CompileError,
        description: """
        The module #{env.module} does not implement the on_connected/2 method!

        You can copy paste a default implementation below:
          def on_connected(_options, state) do
            state
          end
        """
    end
  end

  @doc """
  Send one or more frames over the given websocket.

  `websocket` is the pid of the websocket, `frame_or_frames` is one (or a list of) `t:frame/0`.
  """
  @spec send(websocket :: pid(), frame_or_frames :: frame() | [frame()]) :: :ok
  def send(websocket, frame_or_frames) do
    GenServer.call(websocket, {:send, frame_or_frames})
  end

  defdelegate start_link(module, init_args, options), to: GenServer

  defdelegate start_link(module, init_args), to: GenServer
end
