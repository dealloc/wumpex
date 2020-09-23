defmodule Wumpex.Api.Ratelimit.StatelessBucket do
  @moduledoc """
  Represents a single "bucket" in the rate limit system of Discord as described in the [official documentation](https://discord.com/developers/docs/topics/rate-limits#rate-limits).

  Buckets are responsible for checking whether the given request is allowed to execute, and if not queue or bounce the request according to the given configuration.
  The StatelessBucket module gets an ETS table passed in on every request that contains the state for that specific bucket.
  This allows executing multiple requests on the same Discord bucket (but spread across multiple processes) and having a worker pool of buckets (using `:poolboy`).
  """

  use GenServer

  alias HTTPoison.Request
  alias HTTPoison.Response
  alias Wumpex.Api

  require Logger

  @typedoc """
  Contains all the information required for making a HTTP call.

  The elements correspond to the parameters of `Wumpex.Api.request/5`.
  """
  @type http_call ::
          {Request.method(), Request.url(), Request.body(), Request.headers(), Request.options()}

  @typedoc """
  Represents the result of an executed `t:http_call/0`.
  """
  @type http_response :: {:ok, Response.t()} | {:error, HTTPoison.Error.t() | Response.t()}

  @typedoc """
  Represents a command for the bucket to execute.

  Each command contains 4 fields:
  * `:http` - A `t:http_call/0` that represents the HTTP call to execute (if possible).
  * `:timeout` - A `t:timeout/0` that indicates how long the caller is willing to wait in case we need to queue.
  * `:state` - An `t::ets.tid/0` table that contains the state for the http call resource (eg. remaining rate limit, reset, ...).
  * `:bucket` - The name of the bucket in which this command will execute (used for state lookup).
  """
  @type command :: %{
          http: http_call(),
          timeout: timeout(),
          state: :ets.tid(),
          bucket: any()
        }

  @typedoc """
  This module does not keep any state in the process.
  """
  @type state :: nil

  @typedoc """
  The state stored in the `:ets` table passed in `t:command/0`.
  """
  @type bucket_state :: %{
          remaining: non_neg_integer() | nil,
          reset_at: non_neg_integer() | nil
        }

  @doc false
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @doc false
  @impl GenServer
  @spec init(any()) :: {:ok, state()}
  def init(_options) do
    {:ok, nil}
  end

  @doc false
  @impl GenServer
  @spec handle_call(command(), GenServer.from(), state()) ::
          {:reply, http_response() | {:error, :bounced}, state()}
  def handle_call(%{http: http_call, timeout: timeout} = command, _from, state) do
    response =
      case can_execute_in(command) do
        0 ->
          http_call
          |> execute()
          |> update_ratelimits(command)

        delay when delay <= timeout ->
          Logger.debug("Delaying #{inspect(http_call)} with #{delay}ms")
          Process.sleep(delay)

          http_call
          |> execute()
          |> update_ratelimits(command)

        _delay ->
          {:error, :bounced}
      end

    {:reply, response, state}
  end

  @doc """
  Executes the given `t:http_call/0` and returns the `t:http_response/0`.

  Calls are executed using `Wumpex.Api.request/5`.
  """
  @spec execute(http_call()) :: http_response()
  def execute({method, url, body, headers, options} = http_call) do
    response = Api.request(method, url, body, headers, options)

    Logger.debug("Executed #{inspect(http_call)} -> #{inspect(response)}")

    case response do
      {:ok, %{status_code: status_code} = response} when status_code > 299 ->
        {:error, response}

      response ->
        response
    end
  end

  # Returns how many milliseconds until a request can be made, returns 0 if one can be made immediately.
  @spec can_execute_in(command()) :: non_neg_integer()
  defp can_execute_in(command) do
    %{remaining: remaining, reset_at: reset_at} = get_state(command)

    case remaining do
      0 ->
        max(reset_at - :os.system_time(:millisecond), 0)

      _remaining ->
        0
    end
  end

  # Update the rate limits with the information found in the HTTP response (if any).
  @spec update_ratelimits(http_response(), command()) :: http_response()
  defp update_ratelimits({_state, %{headers: headers}} = response, command) do
    headers
    |> Map.new()
    |> update_ratelimits_with_headers(command)

    response
  end

  # No headers were present on the response (usually an error), no-op.
  defp update_ratelimits(response, _command), do: response

  @spec get_state(command()) :: bucket_state()
  defp get_state(%{state: table, bucket: bucket}) do
    case :ets.lookup(table, bucket) do
      [] ->
        raise "Could not find state for #{inspect(bucket)}!"

      [{^bucket, state}] ->
        state
    end
  end

  # Performs the actual update of the ETS table with the ratelimit state information.
  # We had to split this out in a separate method since the typespec doesn't recognize the http response headers as maps
  @spec update_ratelimits_with_headers(map(), command()) :: :ok
  defp update_ratelimits_with_headers(
         %{"x-ratelimit-remaining" => remaining, "x-ratelimit-reset" => reset_at} = headers,
         %{state: table, bucket: bucket}
       ) do
    bucket = Map.get(headers, "x-ratelimit-bucket", bucket)

    :ets.insert(
      table,
      {bucket,
       %{
         remaining: remaining,
         reset_at: reset_at
       }}
    )

    :ok
  end

  # No rate limit headers found in the header list, no-op.
  defp update_ratelimits_with_headers(_headers, _command), do: :ok
end
