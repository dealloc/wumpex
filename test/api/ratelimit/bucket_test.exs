defmodule Wumpex.Api.Ratelimit.BucketTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response
  alias Wumpex.Api.Ratelimit.Bucket

  @moduletag :integration
  doctest Wumpex.Api.Ratelimit.Bucket

  describe "handle_call should" do
    test_with_server "execute calls immediately when there's remaining set" do
      route("/test", Response.ok(""))

      {:ok, bucket} =
        Bucket.start_link(
          name: "test-bucket",
          remaining: 1,
          reset_at: :os.system_time(:millisecond) + 10_000
        )

      assert {:ok, _response} =
               GenServer.call(
                 bucket,
                 {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []},
                 500
               )

      assert request_received("/test", method: "GET")
    end

    test_with_server "queue calls when there's a 0 remaining set" do
      route("/test", Response.ok(""))

      {:ok, bucket} =
        Bucket.start_link(
          name: "test-bucket",
          remaining: 0,
          reset_at: :os.system_time(:millisecond) + 100
        )

      try do
        {:ok, _response} =
          GenServer.call(
            bucket,
            {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []},
            50
          )
      catch
        :exit, {:timeout, _reason} ->
          :timeout
      else
        _result ->
          flunk("GenServer.call did not timeout!")
      end
    end

    test_with_server "execute queued calls when the reset_at expires" do
      route("/test", Response.ok(""))

      {:ok, bucket} =
        Bucket.start_link(
          name: "test-bucket",
          remaining: 0,
          reset_at: :os.system_time(:millisecond) + 100
        )

      task =
        Task.async(fn ->
          GenServer.call(bucket, {:get, "http://localhost:#{FakeServer.port()}/test", "", [], []})
        end)

      refute request_received("/test")

      Task.await(task, 1_000)

      assert request_received("/test")
    end
  end
end
