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
                 {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, :infinity},
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
            {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, :infinity},
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
          GenServer.call(
            bucket,
            {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, :infinity}
          )
        end)

      refute request_received("/test")

      Task.await(task, 1_000)

      assert request_received("/test")
    end

    test_with_server "reject a call when it can't be executed before the reset_at" do
      route("/test", Response.ok(""))

      {:ok, bucket} =
        Bucket.start_link(
          name: "test-bucket",
          remaining: 0,
          reset_at: :os.system_time(:millisecond) + 10_000
        )

      # reset_at expires in 10s, we indicate we wait max 100ms.
      {:error, :bounced} =
        GenServer.call(
          bucket,
          {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, 100},
          1_000
        )

      refute request_received("/test")
    end

    test_with_server "update the limits according to the response" do
      route("/test", [
        Response.ok("", %{
          "x-ratelimit-remaining" => "0",
          "x-ratelimit-reset" => "#{:os.system_time(:millisecond) + 120}.0"
        }),
        Response.ok("")
      ])

      {:ok, bucket} = Bucket.start_link(name: "test-bucket", remaining: nil, reset_at: nil)

      assert {:ok, response} =
               GenServer.call(
                 bucket,
                 {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, 0}
               )

      task =
        Task.async(fn ->
          assert {:ok, response} =
                   GenServer.call(
                     bucket,
                     {{:get, "http://localhost:#{FakeServer.port()}/test", "", [], []}, 150}
                   )
        end)

      assert request_received("/test", count: 1)
      Task.await(task)
      assert request_received("/test", count: 2)
    end
  end
end
