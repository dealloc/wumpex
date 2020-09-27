defmodule Wumpex.Api.Ratelimit do
  @moduledoc """
  The `Wumpex.Api.Ratelimit` module handles dispatching HTTP requests through the `Wumpex.Api` module, but handles rate limits.

  ## Examples
      iex> Wumpex.Api.Ratelimit.get("http://localhost/test")
      {:ok, _response}
  """

  use GenServer

  alias Wumpex.Api.Ratelimit.StatelessBucket, as: Bucket
  alias Wumpex.Api.Ratelimit.Well

  # external identifier for buckets (multiple of these may refer to the same bucket!)
  @type bucket_tag :: tuple()

  @typedoc """
  The state of the `Wumpex.Api.Ratelimit` process.

  Contains the following values:
  * `:buckets` - The `:ets` table containing all the bucket identifiers
  * `:bucket_states` - The `:ets` table containing the state for all buckets.
  * `:well` - The `t:GenServer.server/0` of the `Wumpex.Api.Ratelimit.Well` process.
  """
  @type state :: %{
          buckets: :ets.tid(),
          bucket_states: :ets.tid(),
          well: GenServer.server()
        }

  @worker_pool __MODULE__.BucketPool

  @doc """
  Executes a given request using `Wumpex.Api.request/5` using ratelimits.

  This means that if a rate limit would be encountered the request will either be bounced or delayed, depending on the configured timeout and when the resource will become available.

  For example, imagine the URL `"/test"` can be called once per 10 seconds:
      iex> Wumpex.Api.Ratelimit.request({:get, "http://localhost/test", "", [], []}, {"ratelimit", "demo"})
        {:ok, %HTTPoison.Response{}}
      iex> Wumpex.Api.Ratelimit.request({:get, "http://localhost/test", "", [], []}, {"ratelimit", "demo"})
        {:error, :bounced}

  The first request executes and returns the response (an instance of `t:HTTPoison.Response.t/0`), but the second request gets `{:error, :bounced}`.
  This is because after the first request we'd have to wait 10s, while we specified we only want to wait up to 5s (default, can be overriden by passing in a third parameter).
  If we'd have passed in 11s for example, the request would have been delayed 10s before executing, after which the response would be returned.

  You can choose to *always* execute the request, regardless of how long it would take until it can execute by passing `:infinity` as the third parameter.
  """
  @spec request(Bucket.http_call(), bucket_tag(), timeout()) :: Bucket.http_response() | {:error, :bounced}
  def request(http_call, tag, timeout \\ 5_000) do
    GenServer.call(__MODULE__, {http_call, tag, timeout}, :infinity)
  end

  @doc false
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc false
  @impl GenServer
  @spec init(any()) :: {:ok, state()}
  def init(_options) do
    {:ok, well} = Well.start_link()
    # Start the bucket worker pool as part of the ratelimit supervision tree.
    {:ok, _pool} = :poolboy.start_link([
      name: {:local, @worker_pool},
      worker_module: Wumpex.Api.Ratelimit.StatelessBucket,
      size: Application.get_env(:wumpex, :buckets, 4),
      max_overflow: Application.get_env(:wumpex, :buckets, 4)
    ], [])
    buckets = :ets.new(:wumpex_buckets, [:public])

    bucket_states =
      :ets.new(:wumpex_bucket_states, [
        :public,
        {:write_concurrency, true},
        {:read_concurrency, true}
      ])

    {:ok,
     %{
       buckets: buckets,
       bucket_states: bucket_states,
       well: well
     }}
  end

  @impl GenServer
  @spec handle_call({Bucket.http_call(), bucket_tag(), timeout()}, GenServer.from(), state()) ::
          {:noreply, state()}
  def handle_call({http_call, bucket_tag, timeout}, from, state) do
    case lookup_bucket(state.buckets, bucket_tag) do
      nil ->
        forward_call(
          state.well,
          %{
            http: http_call,
            tag: bucket_tag,
            buckets: state.buckets,
            bucket_states: state.bucket_states
          },
          from
        )

      bucket ->
        :poolboy.transaction(
          @worker_pool,
          fn pid ->
            forward_call(
              pid,
              %{
                http: http_call,
                timeout: timeout,
                state: state.bucket_states,
                bucket: bucket
              },
              from
            )
          end,
          timeout
        )
    end

    {:noreply, state}
  end

  # Lookup the given bucket name for a given bucket tag.
  @spec lookup_bucket(:ets.tid(), bucket_tag()) :: String.t() | nil
  defp lookup_bucket(table, bucket_tag) do
    case :ets.lookup(table, bucket_tag) do
      [] ->
        nil

      [{^bucket_tag, bucket}] ->
        bucket
    end
  end

  # This method forwards a call to another genserver.
  # We use this method to forward a request to the ratelimit to the bucket which will then handle it.
  # Forwarding instead of simply calling GenServer.call to the bucket allows the ratelimit to continue processing without blocking.
  @spec forward_call(server :: GenServer.server(), event :: any(), from :: GenServer.from()) ::
          :ok
  defp forward_call(server, event, from) do
    target = GenServer.whereis(server)

    send(target, {:"$gen_call", from, event})
    :ok
  end
end
