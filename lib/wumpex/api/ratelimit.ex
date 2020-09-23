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

  @doc """
  Executes a GET request to the given `url`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.get("http://localhost/test")
        {:ok, response}
  """
  @spec get(url :: String.t(), options :: HTTPoison.options()) :: Bucket.http_response()
  def get(url, options \\ []) do
    GenServer.call(__MODULE__, {:get, url, "", options}, 5_000)
  end

  @doc """
  Executes a GET request to the given `url` while waiting for a given `t:timeout/0`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.get("http://localhost/test", 5_000)
        {:ok, response}
  """
  @spec get(url :: String.t(), options :: HTTPoison.options(), timeout :: timeout()) ::
          Bucket.http_response()
  def get(url, options, timeout) do
    GenServer.call(__MODULE__, {:get, url, "", options}, timeout)
  end

  @doc """
  Executes a POST request to the given `url` with a given `body`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.post("http://localhost/test", %{"hello" => "world"})
        {:ok, response}
  """
  @spec post(url :: HTTPoison.url(), body :: HTTPoison.body(), options :: HTTPoison.options()) ::
          Bucket.http_response()
  def post(url, body, options \\ []) do
    GenServer.call(__MODULE__, {:post, url, body, options}, 5_000)
  end

  @doc """
  Executes a POST request to the given `url` with a given `body`, while waiting for a given `t:timeout/0`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.post("http://localhost/test", %{"hello" => "world"}, 5_000)
        {:ok, response}
  """
  @spec post(
          url :: HTTPoison.url(),
          body :: HTTPoison.body(),
          options :: HTTPoison.options(),
          timeout :: timeout()
        ) :: Bucket.http_response()
  def post(url, body, options, timeout) do
    GenServer.call(__MODULE__, {:post, url, body, options}, timeout)
  end

  @doc """
  Executes a PUT request to the given `url` with a given `body`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.put("http://localhost/test", %{"hello" => "world"})
        {:ok, response}
  """
  @spec put(url :: HTTPoison.url(), body :: HTTPoison.body(), options :: HTTPoison.options()) ::
          Bucket.http_response()
  def put(url, body, options \\ []) do
    GenServer.call(__MODULE__, {:put, url, body, options}, 5_000)
  end

  @doc """
  Executes a PUT request to the given `url` with a given `body`, while waiting for a given `t:timeout/0`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.put("http://localhost/test", %{"hello" => "world"}, 5_000)
        {:ok, response}
  """
  @spec put(
          url :: HTTPoison.url(),
          body :: HTTPoison.body(),
          options :: HTTPoison.options(),
          timeout :: timeout()
        ) :: Bucket.http_response()
  def put(url, body, options, timeout) do
    GenServer.call(__MODULE__, {:put, url, body, options}, timeout)
  end

  @doc """
  Executes a PATCH request to the given `url` with a given `body`.

  ## Examples
      iex> Wumpex.Api.Ratelimit.patch("http://localhost/test", %{"hello" => "world"})
      {:ok, response}
  """
  @spec patch(url :: HTTPoison.url(), body :: HTTPoison.body(), options :: HTTPoison.options()) ::
          Bucket.http_response()
  def patch(url, body, options \\ []) do
    GenServer.call(__MODULE__, {:patch, url, body, options}, 5_000)
  end

  @doc """
  Executes a PATCH request to the given `url` with a given `body`, while waiting for a given `t:timeout/0`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.patch("http://localhost/test", %{"hello" => "world"}, 5_000)
        {:ok, response}
  """
  @spec patch(
          url :: HTTPoison.url(),
          body :: HTTPoison.body(),
          options :: HTTPoison.options(),
          timeout :: timeout()
        ) :: Bucket.http_response()
  def patch(url, body, options, timeout) do
    GenServer.call(__MODULE__, {:patch, url, body, options}, timeout)
  end

  @doc """
  Executes a DELETE request to the given `url`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.delete("http://localhost/test")
        {:ok, response}
  """
  @spec delete(url :: String.t(), options :: HTTPoison.options()) :: Bucket.http_response()
  def delete(url, options \\ []) do
    GenServer.call(__MODULE__, {:delete, url, "", options}, 5_000)
  end

  @doc """
  Executes a DELETE request to the given `url` while waiting for a given `t:timeout/0`.

  ## Examples
        iex> Wumpex.Api.Ratelimit.delete("http://localhost/test", 5_000)
        {:ok, response}
  """
  @spec delete(url :: String.t(), options :: HTTPoison.options(), timeout :: timeout()) ::
          Bucket.http_response()
  def delete(url, options, timeout) do
    GenServer.call(__MODULE__, {:delete, url, "", options}, timeout)
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
            buckets: state.buckets
          },
          from
        )

      bucket ->
        :poolboy.transaction(
          :wumpex_buckets,
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
