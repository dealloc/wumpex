defmodule Wumpex.Api.Ratelimit.Bucket do
  use GenServer

  alias HTTPoison.Request
  alias HTTPoison.Response
  alias Wumpex.Api

  require Logger

  @typedoc """
  The options that can be given to `start_link/1`.

  Note that `:remaining` and `:reset_at` are only used for setting an initial state (see `t:state/0`),
  and are overwritten with values from the responses when approperiate.

  Contains the following values:
  * `:name` - The name of the bucket, this is used for logging to allow easier debugging.
  * `:remaining` - The initial amount of remaining requests that this bucket can still make, can be nil.
  * `:reset_at` - The initial reset timestamp (unix epoch in millseconds), can be nil.
  """
  @type options :: [
          name: String.t(),
          remaining: non_neg_integer() | nil,
          reset_at: non_neg_integer() | nil
        ]

  @type state :: %{
          remaining: non_neg_integer() | nil,
          reset_at: non_neg_integer() | nil,
          queue: :queue.queue(queued_call()),
          dequeue_pending: boolean()
        }

  @typedoc """
  Contains all the information required for making a HTTP call.

  The elements correspond to the parameters of `Wumpex.Api.request/5`.
  """
  @type http_call ::
          {Request.method(), Request.url(), Request.body(), Request.headers(), Request.options()}

  @type queued_call :: {http_call(), GenServer.from()}

  def test do
    {:ok, bucket} =
      __MODULE__.start_link(
        name: "test-bucket",
        remaining: 0,
        reset_at: :os.system_time(:millisecond) + 10_000
      )

    GenServer.call(bucket, {:get, "/", "", [], []})
  end

  @spec start_link(options :: options()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, [])
  end

  @impl GenServer
  @spec init(options :: options()) :: {:ok, state()}
  def init(name: bucket, remaining: remaining, reset_at: reset_at) do
    Logger.metadata(bucket: bucket)

    Logger.info("Started bucket #{inspect(bucket)}")

    {:ok,
     %{
       remaining: remaining,
       reset_at: reset_at,
       queue: :queue.new(),
       dequeue_pending: false
     }}
  end

  # TODO: allow the client to let us know how long we want to wait before the timeout.
  # If the client waits max 5_000ms and the resource would take more, we shouldn't execute this at all, it'd fail anyway.
  @impl GenServer
  @spec handle_call(http_call :: http_call(), from :: GenServer.from(), state :: state()) ::
          {:reply, any(), state()} | {:noreply, state()}
  def handle_call(http_call, from, state) do
    case execute_or_queue(http_call, from, state) do
      {:queued, state} ->
        {:noreply, state}

      {response, state} ->
        {:reply, response, state}
    end
  end

  # Processes whatever calls are pending in the queue until the queue or the available requests run out.
  @impl GenServer
  @spec handle_info(:dequeue | :timeout, state()) ::
          {:noreply, state(), timeout()} | {:noreply, state(), :hibernate}
  def handle_info(:dequeue, state) do
    state =
      state
      |> maybe_reset_remaining()
      |> dequeue()

    Logger.debug("Finished dequeue, #{:queue.len(state.queue)} items left in queue.")
    {:noreply, %{state | dequeue_pending: false}, 60_000}
  end

  # Called when the bucket didn't receive a message for 60s, we're hibernating the process.
  @impl GenServer
  def handle_info(:timeout, state), do: {:noreply, state, :hibernate}

  @spec execute_or_queue(http_call(), GenServer.from(), state()) ::
          {:queued, state}
          | {{:ok, Response.t()}, state()}
          | {{:ok, Response.t()}, state()}
          | {{:error, HTTPoison.Error.t() | Response.t()}, state()}
  defp execute_or_queue(http_call, from, state) do
    case can_execute?(state) do
      false ->
        {:queued, queue_call(http_call, from, state)}

      true ->
        {execute(http_call), state}
    end
  end

  # Check if a request can execute according to the current state.
  @spec can_execute?(state()) :: boolean()
  defp can_execute?(%{remaining: remaining, reset_at: reset_at}) do
    case remaining do
      0 ->
        # Check that the "reset_at" has passed, because then the remaining has been invalidated.
        :os.system_time(:millisecond) >= reset_at

      _remaining ->
        true
    end
  end

  # Add a given HTTP call to the queue to be executed later.
  @spec queue_call(http_call(), GenServer.from(), state()) :: state()
  defp queue_call(http_call, from, state) do
    state = maybe_schedule_dequeue(state)

    Logger.debug("Queue #{inspect(http_call)}")
    %{state | queue: :queue.in({http_call, from}, state.queue)}
  end

  # Execute the given HTTP call.
  @spec execute(http_call()) :: {:ok, Response.t()} | {:error, HTTPoison.Error.t() | Response.t()}
  defp execute({method, url, body, headers, options} = http_call) do
    response = Api.request(method, url, body, headers, options)

    Logger.debug("Executed #{inspect(http_call)} -> #{inspect(response)}")

    case response do
      {:ok, %{status_code: status_code} = response} when status_code > 299 ->
        {:error, response}

      response ->
        response
    end
  end

  # There's already a dequeue pending, we just skip the scheduling.
  @spec maybe_schedule_dequeue(state()) :: state()
  defp maybe_schedule_dequeue(%{dequeue_pending: true} = state), do: state

  # If there's no dequeue (execute queued messages) scheduled, schedule one now.
  defp maybe_schedule_dequeue(%{reset_at: reset_at} = state) do
    # Calculate how many milliseconds to wait before sending a dequeue, no less than 0ms,
    # and pad with 100ms to provide some buffer.
    delta = max(reset_at - :os.system_time(:millisecond), 0) + 100

    case delta do
      100 ->
        # We are scheduling a dequeue, but the reset_at has passed, we schedule one immediately.
        Logger.debug("Scheduled dequeue immediately")
        send(self(), :dequeue)

      _epoch ->
        Logger.debug("Scheduled dequeue in #{delta}ms")
        Process.send_after(self(), :dequeue, delta)
    end

    %{state | dequeue_pending: true}
  end

  # Checks if we can execute requests (aka there's remaining or the reset_at has expired) and resets the remaining to nil.
  @spec maybe_reset_remaining(state()) :: state()
  defp maybe_reset_remaining(state) do
    case can_execute?(state) do
      false ->
        state

      true ->
        %{state | remaining: nil}
    end
  end

  # If there's calls left on the queue, attempt to execute them until remaining is 0
  @spec dequeue(state()) :: state()
  defp dequeue(%{remaining: 0} = state), do: maybe_schedule_dequeue(state)

  defp dequeue(%{queue: queue} = state) do
    case :queue.out(queue) do
      {:empty, queue} ->
        # Queue is empty, we're done here!
        %{state | queue: queue}

      {{:value, {http_call, from}}, queue} ->
        {response, state} = execute_or_queue(http_call, from, %{state | queue: queue})
        # Let the waiting client know about the response.
        GenServer.reply(from, response)
        dequeue(state)
    end
  end
end
