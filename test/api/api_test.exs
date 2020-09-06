defmodule Wumpex.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Wumpex.Api

  @moduletag :integration
  doctest Wumpex.Api

  setup_all do
    {:ok, webserver } = WebServerHelper.start_link()

    {:ok, [
      server: webserver
    ]}
  end

  describe "Wumpex.Api parse ratelimit headers" do
    test "if absent in response" do
      {:ok, response} = Api.get("/no-ratelimit")

      assert %{
        "retry-after" => nil,
        "x-ratelimit-remaining" => nil,
        "x-ratelimit-reset" => nil
      } = response.headers
    end

    test "if present response" do
      {:ok, response} = Api.get("/passing-ratelimit")

      assert %{
        "retry-after" => 0,
        "x-ratelimit-remaining" => 5,
        "x-ratelimit-reset" => reset
      } = response.headers

      assert is_number(reset)
    end

    test "from a 429 response" do
      {:ok, response} = Api.get("/failing-ratelimit")

      assert %{
        "retry-after" => 1_000,
        "x-ratelimit-remaining" => 0,
        "x-ratelimit-reset" => reset
      } = response.headers

      assert is_number(reset)
    end
  end

  describe "Wumpex.Api should parse JSON body" do
    test "if present" do
      {:ok, response} = Api.get("/json-body")

      assert %{"hello" => "world"} = response.body
    end

    test "ONLY if present" do
      {:ok, response} = Api.get("/empty-body")

      assert "" = response.body
    end
  end

  describe "Wumpex.Api should send" do
    test "User-Agent header" do
      {:ok, response} = Api.get("/echo-headers")

      assert %{
        "user-agent" => _
      } = response.headers
    end

    test "Content-Type header" do
      {:ok, response} = Api.get("/echo-headers")

      assert %{
        "content-type" => _
      } = response.headers
    end

    test "Authorization header" do
      {:ok, response} = Api.get("/echo-headers")

      header = "Bot #{Wumpex.token()}"
      assert %{
        "authorization" => ^header
      } = response.headers
    end

    test "X-Ratelimit-Precision header" do
      {:ok, response} = Api.get("/echo-headers")

      assert %{
        "x-ratelimit-precision" => "millisecond"
      } = response.headers
    end

    test "Optional custom headers" do
      {:ok, response} = Api.get("/echo-headers", [
        "X-Wumpex-Test-Header": "passed"
      ])

      assert %{
        "x-wumpex-test-header" => "passed"
      } = response.headers
    end
  end
end
