defmodule Wumpex.Api.Ratelimit.Well do
  @moduledoc """
  The well handles requests for routes which Wumpex doesn't know the bucket for.

  It executes the incoming requests, and then attempts to associate the key for that route to a bucket.
  """

  use GenServer

  alias Wumpex.Api.Ratelimit
  alias Wumpex.Api.Ratelimit.StatelessBucket, as: Bucket

  @typedoc """
  This module does not keep any state in the process.
  """
  @type state :: nil

  @type command :: %{
          http: Bucket.http_call(),
          tag: Ratelimit.bucket_tag(),
          buckets: :ets.tid(),
          bucket_states: :ets.tid()
        }

  @doc false
  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  @spec init(keyword()) :: {:ok, state()}
  def init(_options) do
    {:ok, nil}
  end

  @impl GenServer
  @spec handle_call(command(), GenServer.from(), state()) :: {:reply, any(), state()}
  def handle_call(%{http: http_call} = command, _from, state) do
    response =
      http_call
      |> Bucket.execute()
      |> associate_bucket(command)

    {:reply, response, state}
  end

  # Attempt to extract the bucket name from the response,
  # and associate with the bucket tag if possible.
  @spec associate_bucket(Bucket.http_response(), command()) :: Bucket.http_response()
  defp associate_bucket({_status, %{headers: headers}} = response, %{buckets: buckets, bucket_states: bucket_states, tag: tag}) do
    headers = Map.new(headers)
    bucket = Map.get(headers, "x-ratelimit-bucket", nil)
    remaining = Map.get(headers, "x-ratelimit-remaining", 0)
    reset_at = Map.get(headers, "x-ratelimit-reset", 0) + :os.system_time(:millisecond)

    if bucket != nil do
      :ets.insert(buckets, {tag, bucket})
      :ets.insert(bucket_states, {bucket, %{remaining: remaining, reset_at: reset_at}})
    end

    response
  end

  # No headers found on the response, no-op.
  defp associate_bucket(response, _command), do: response
end
