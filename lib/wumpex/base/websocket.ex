defmodule Wumpex.Base.Websocket do
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

  ## Example

  A module implementing the behaviour will be able to respond to incoming messages by implementing `handle_frame`:

      defmodule ExampleWebsocket do
        use Wumpex.Base.Websocket

        require Logger

        def on_connected(_headers, state) do
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

  @doc """
  Invoked when the websocket connects to the server.

  This method is invoked *every* time the websocket connects.
  So when the connection is severed and the websocket reconnects this method will be invoked again.
  This method can be compared with the `init/1` method of the `GenServer`, and is used to set the state of the process.

  The first parameter passed are the headers received when upgrading the connection to a websocket connection,
  the second parameter is the current state of the process (when reconnecting) or `nil` (on first connect).

  The returned value will be used as the process state.
  """
  @callback on_connected(headers :: keyword(), state :: term() | nil) :: term()

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

  @doc false
  defmacro __using__(options) do
    quote location: :keep, bind_quoted: [options: options] do
      use GenServer, restart: :transient

      alias Wumpex.Base.Websocket

      @behaviour Websocket
      @before_compile Websocket

      @type frame_or_frames :: Websocket.frame() | [Websocket.frame()]

      @spec start_link(options :: Websocket.options() | keyword()) ::
              GenServer.on_start()
      def start_link(options) do
        Websocket.start_link(__MODULE__, options)
      end

      defoverridable start_link: 1

      @doc false
      @impl GenServer
      defdelegate init(_options), to: Websocket

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
      def handle_call({:send, frame_or_frames}, _from, state) do
        {:reply, send_frame(frame_or_frames), state}
      end

      @spec send_frame(frame_or_frames()) :: :ok
      defp send_frame(frame_or_frames) do
        conn = Process.get(:"$websocket", nil)

        :gun.ws_send(conn, frame_or_frames)
      end
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:handle_frame, 2}) do
      IO.warn("""
      The function handle_frame/2 is required by the Websocket behaviour but not implemented in #{inspect(env.module)}.

      A dummy implementation will be injected:

        @impl Websocket
        def handle_frame(_frame, state) do
          {:noreply, state}
        end

      You can copy the implementation above in your module and modify it to suit your needs.
      """, Macro.Env.stacktrace(env))

      quote do
        @doc false
        @impl Wumpex.Base.Websocket
        def handle_frame(_frame, state) do
          {:noreply, state}
        end

        unless Module.defines_type?(__MODULE__, {:state, 0}) do
          @type state :: term()
        end

        defoverridable handle_frame: 2
      end
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

  # Called as init/1 of the GenServer.
  # When a module "use"s this module the init/1 is a defdelegate to this method.
  @doc false
  @spec init(options :: options()) :: {:ok, term()}
  def init(host: host, port: port, path: path, timeout: timeout) do
    Logger.metadata(url: "#{host}:#{port}#{path}")

    Logger.debug("Connecting to #{host}:#{port}#{path}...")
    # We should probably pass in :retry_fun, allowing to tweak the reconnect policy.
    {:ok, conn} = :gun.open(:binary.bin_to_list(host), port, %{protocols: [:http]})
    {:ok, :http} = :gun.await_up(conn, timeout)
    stream = :gun.ws_upgrade(conn, path)

    # :gun.wait does not support :gun_upgrade etc.
    state =
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
          Logger.error("Failed to connect to #{host}: Did not connect within #{inspect(timeout)}")
          exit({:error, :timeout})
      end

    # If the Gun process dies we want to die as well.
    Process.link(conn)

    # Since the implementing module controls state, we put the conn in the process dictionary (I'm open to suggestions).
    Process.put(:"$websocket", conn)
    {:ok, state}
  end
end
