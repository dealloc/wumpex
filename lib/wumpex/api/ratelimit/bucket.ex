defmodule Wumpex.Api.Ratelimit.Bucket do
  @moduledoc """
  Represents a single "bucket" in the rate limit system of Discord as described in the [official documentation](https://discord.com/developers/docs/topics/rate-limits#rate-limits).

  Buckets are responsible for checking whether the given request is allowed to execute, and if not queue or bounce the request according to the given configuration.
  """

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

  @typedoc """
  The state of the process.

  Contains the following fields:
  * `:remaining` - The amount of remaining requests, or `nil` if it's unknown (initial value, or after a reset by `maybe_reset_remaining/1`).
  * `:reset_at` - The unix timestamp when the `:remaining` field expires (and can be reset), or `nil` when it's unknown.
  * `:queue` - An erlang `t::queue.queue/1` that represents all queued calls (see also `t:queued_call/0`).
  * `:dequeue_pending` - Whether a dequeue has already been scheduled (this flag prevents scheduling more than one dequeue at a time, preventing flooding the mailbox in higher traffic), see `handle_info/3` for the dequeue being executed.
  """
  @type state :: %{
          remaining: non_neg_integer() | nil,
          reset_at: non_neg_integer() | nil,
          queue: :queue.queue(queued_call()),
          dequeue_pending: boolean()
        }

  @typedoc """
  Represents a timestamp that indicates the expiration (usually of the `:remaining` field), or `:infinity` if no expiration is applicable.

  This is merely a semantic distinction from the default `t:timeout/0` type, where `t:timeout/0` indicates a relative timestamp, where `t:expiration/0` is used to indicate an absolute timestamp.
  """
  @type expiration :: timeout()

  @typedoc """
  Contains all the information required for making a HTTP call.

  The elements correspond to the parameters of `Wumpex.Api.request/5`.
  """
  @type http_call ::
          {Request.method(), Request.url(), Request.body(), Request.headers(), Request.options()}

  @typedoc """
  Represents a `t:http_call/0` as it's represented in the queue.

  Contains the following values:
  * A `t:http_call/0` which represents the call that's queued.
  * A `t:GenServer.from/0` if the call came from `handle_call/3` and we need to answer or `nil`, which indicates that no one is waiting for the response of this call.
  * A `t:expiration/0` which is either a unix timestamp (in milliseconds) when the call "expires", or `:infinity` if it never expires.
  """
  @type queued_call :: {http_call(), GenServer.from() | nil, expiration()}

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

  @impl GenServer
  @spec handle_call({http_call(), timeout()}, GenServer.from(), state()) ::
          {:reply, any(), state()} | {:noreply, state()}
  def handle_call({http_call, timeout}, from, state) do
    case execute_or_queue(http_call, timeout, from, state) do
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

  @spec execute_or_queue(http_call(), timeout(), GenServer.from(), state()) ::
          {:queued, state}
          | {{:ok, Response.t()}, state()}
          | {{:ok, Response.t()}, state()}
          | {{:error, HTTPoison.Error.t() | Response.t() | :bounced}, state()}
  defp execute_or_queue(http_call, timeout, from, state) do
    result =
      case can_execute_in(state) do
        0 ->
          {execute(http_call), state}

        delay when delay >= timeout ->
          {{:error, :bounced}, state}

        _delay ->
          {:queued, queue_call(http_call, from, state)}
      end

    update_rates(result)
  end

  # Returns how many milliseconds until a request can be made, returns 0 if one can be made immediately.
  @spec can_execute_in(state()) :: non_neg_integer()
  defp can_execute_in(%{remaining: remaining, reset_at: reset_at}) do
    case remaining do
      0 ->
        # Check that the "reset_at" has passed, because then the remaining has been invalidated.
        max(reset_at - :os.system_time(:millisecond), 0)

      _remaining ->
        0
    end
  end

  # Add a given HTTP call to the queue to be executed later.
  @spec queue_call(http_call(), GenServer.from(), state()) :: state()
  defp queue_call(http_call, from, state) do
    state = maybe_schedule_dequeue(state)

    Logger.debug("Queueing #{inspect(http_call)}")
    %{state | queue: :queue.in({http_call, from, :infinity}, state.queue)}
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

  # Checks if we can execute requests (aka there's remaining or the reset_at has expired)
  # and resets the remaining to nil.
  @spec maybe_reset_remaining(state()) :: state()
  defp maybe_reset_remaining(state) do
    case can_execute_in(state) do
      0 ->
        %{state | remaining: nil}

      _delay ->
        state
    end
  end

  # If there's no remaining, stop dequeueing and optionally schedule a dequeue.
  @spec dequeue(state()) :: state()
  defp dequeue(%{remaining: 0} = state), do: maybe_schedule_dequeue(state)

  # If there's calls left on the queue, attempt to execute them until remaining is 0
  defp dequeue(%{queue: queue} = state) do
    case :queue.out(queue) do
      {:empty, queue} ->
        # Queue is empty, we're done here!
        %{state | queue: queue}

      {{:value, {http_call, from, expiration}}, queue} ->
        waiting_time = max(expiration, :os.system_time(:millisecond))

        {response, state} =
          execute_or_queue(http_call, waiting_time, from, %{state | queue: queue})

        # Let the waiting client know about the response.
        GenServer.reply(from, response)
        dequeue(state)
    end
  end

  # Update the remaining and reset_at according to the information of the response.
  @spec update_rates(
          {:queued, state}
          | {{:ok, Response.t()}, state()}
          | {{:ok, Response.t()}, state()}
          | {{:error, HTTPoison.Error.t() | Response.t() | :bounced}, state()}
        ) ::
          {:queued, state}
          | {{:ok, Response.t()}, state()}
          | {{:ok, Response.t()}, state()}
          | {{:error, HTTPoison.Error.t() | Response.t() | :bounced}, state()}
  defp update_rates(
         {{_,
           %{headers: %{"x-ratelimit-reset" => reset_at, "x-ratelimit-remaining" => remaining}}} =
            response, state}
       ) do
    reset_at = case reset_at do
      nil ->
        nil
      _ when is_number(reset_at) ->
        round(reset_at)
    end

    # We call round/1 since reset_at is parsed as a float, but used as an integer internally.
    {response, %{state | remaining: remaining, reset_at: reset_at}}
  end

  # No headers were passed in the response, either queue, dequeue or error.
  defp update_rates({response, state}), do: {response, state}
end
