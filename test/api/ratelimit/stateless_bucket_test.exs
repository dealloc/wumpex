defmodule Wumpex.Api.Ratelimit.StatelessBucketTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response
  alias Wumpex.Api.Ratelimit.StatelessBucket

  @moduletag :integration
  doctest Wumpex.Api.Ratelimit.StatelessBucket

  describe "Wumpex.Api.Ratelimit.StatelessBucket.handle_call/3 should" do
    test "Bounce the request when it can't be executed within the given timeout." do
      {:ok, bucket} = StatelessBucket.start_link([])
      table = :ets.new(:wumpex_buckets_test, [:public])

      :ets.insert(
        table,
        {"test-bucket", %{remaining: 0, reset_at: :os.system_time(:millisecond) + 10_000}}
      )

      assert {:error, :bounced} =
               GenServer.call(bucket, %{
                 http: {:get, "/", "", [], []},
                 timeout: 1_000,
                 state: table,
                 bucket: "test-bucket"
               })
    end

    test "raise an exception when the state for that bucket is not set" do
      {:ok, bucket} = StatelessBucket.start_link([])

      Process.flag(:trap_exit, true)

      assert catch_exit(
               GenServer.call(bucket, %{
                 http: {:get, "/", "", [], []},
                 timeout: 1_000,
                 state: :ets.new(:wumpex_buckets_test, [:public]),
                 bucket: "test-bucket"
               })
             )
    end

    test_with_server "update the ETS table with information from the response" do
      route("/test", Response.ok("", %{
        "retry-after" => "1000",
        "x-ratelimit-remaining" => "10",
        "x-ratelimit-reset" => "#{:os.system_time(:millisecond)}.0"
      }))

      {:ok, bucket} = StatelessBucket.start_link([])
      table = :ets.new(:wumpex_buckets_test, [:public])

      :ets.insert(
        table,
        {"test-bucket", %{remaining: 1, reset_at: :os.system_time(:millisecond) + 10_000}}
      )

      GenServer.call(bucket, %{
        http: {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []},
        timeout: 1_000,
        state: table,
        bucket: "test-bucket"
      })

      assert [{"test-bucket", %{remaining: 10}}] = :ets.lookup(table, "test-bucket")
    end

    test_with_server "return {:ok, response} when the http call succeeds" do
      route("/test", Response.ok("", %{
        "retry-after" => "1000",
        "x-ratelimit-remaining" => "10",
        "x-ratelimit-reset" => "#{:os.system_time(:millisecond)}.0"
      }))

      {:ok, bucket} = StatelessBucket.start_link([])
      table = :ets.new(:wumpex_buckets_test, [:public])

      :ets.insert(
        table,
        {"test-bucket", %{remaining: 1, reset_at: :os.system_time(:millisecond) + 10_000}}
      )

      {:ok, %HTTPoison.Response{}} = GenServer.call(bucket, %{
        http: {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []},
        timeout: 1_000,
        state: table,
        bucket: "test-bucket"
      })
    end

    test_with_server "return {:error, response} when the http call succeeds with a non 2XX status code" do
      route("/test", Response.unauthorized("", %{
        "retry-after" => "1000",
        "x-ratelimit-remaining" => "10",
        "x-ratelimit-reset" => "#{:os.system_time(:millisecond)}.0"
      }))

      {:ok, bucket} = StatelessBucket.start_link([])
      table = :ets.new(:wumpex_buckets_test, [:public])

      :ets.insert(
        table,
        {"test-bucket", %{remaining: 1, reset_at: :os.system_time(:millisecond) + 10_000}}
      )

      {:error, %HTTPoison.Response{}} = GenServer.call(bucket, %{
        http: {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []},
        timeout: 1_000,
        state: table,
        bucket: "test-bucket"
      })
    end

    test_with_server "return {:error, error} when the http call fails" do
      {:ok, bucket} = StatelessBucket.start_link([])
      table = :ets.new(:wumpex_buckets_test, [:public])

      :ets.insert(
        table,
        {"test-bucket", %{remaining: 1, reset_at: :os.system_time(:millisecond) + 10_000}}
      )

      {:error, %HTTPoison.Error{}} = GenServer.call(bucket, %{
        http: {:get, "http://localhost/test", "", [], []},
        timeout: 1_000,
        state: table,
        bucket: "test-bucket"
      })
    end
  end
end
