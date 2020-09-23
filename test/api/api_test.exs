defmodule Wumpex.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response
  alias Wumpex.Api

  @moduletag :integration
  doctest Wumpex.Api

  describe "Wumpex.Api parse ratelimit headers" do
    test_with_server "if absent in response" do
      route("/no-ratelimit", Response.ok(""))

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/no-ratelimit")

      assert %{
               "x-ratelimit-remaining" => nil,
               "x-ratelimit-reset" => nil
             } = response.headers
    end

    test_with_server "if present response" do
      route(
        "/passing-ratelimit",
        Response.ok("", %{
          "x-ratelimit-remaining" => "5",
          "x-ratelimit-reset" => "#{:os.system_time(:millisecond)}.0"
        })
      )

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/passing-ratelimit")

      assert %{
               "x-ratelimit-remaining" => 5,
               "x-ratelimit-reset" => reset
             } = response.headers

      assert is_number(reset)
    end

    test_with_server "from a 429 response" do
      route(
        "/failing-ratelimit",
        Response.too_many_requests("", %{
          "x-ratelimit-remaining" => "0",
          "x-ratelimit-reset" => "#{:os.system_time(:millisecond)}.0"
        })
      )

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/failing-ratelimit")

      assert %{
               "x-ratelimit-remaining" => 0,
               "x-ratelimit-reset" => reset
             } = response.headers

      assert is_number(reset)
    end
  end

  describe "Wumpex.Api should parse JSON body" do
    test_with_server "if present" do
      route("/json-body", Response.ok(%{"hello" => "world"}))

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/json-body")

      assert %{"hello" => "world"} = response.body
    end

    test_with_server "ONLY if present" do
      route("/empty-body", Response.ok(""))

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/empty-body")

      assert "" = response.body
    end
  end

  describe "Wumpex.Api should send" do
    test_with_server "User-Agent header" do
      route("/echo-headers", fn %{headers: headers} -> Response.ok("", headers) end)

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/echo-headers")

      assert %{
               "user-agent" => _
             } = response.headers
    end

    test_with_server "Content-Type header" do
      route("/echo-headers", fn %{headers: headers} -> Response.ok("", headers) end)

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/echo-headers")

      assert %{
               "content-type" => _
             } = response.headers
    end

    test_with_server "Authorization header" do
      route("/echo-headers", fn %{headers: headers} -> Response.ok("", headers) end)

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/echo-headers")

      header = "Bot #{Wumpex.token()}"

      assert %{
               "authorization" => ^header
             } = response.headers
    end

    test_with_server "X-Ratelimit-Precision header" do
      route("/echo-headers", fn %{headers: headers} -> Response.ok("", headers) end)

      {:ok, response} = Api.get("http://localhost:#{FakeServer.port()}/echo-headers")

      assert %{
               "x-ratelimit-precision" => "millisecond"
             } = response.headers
    end

    test_with_server "Optional custom headers" do
      route("/echo-headers", fn %{headers: headers} -> Response.ok("", headers) end)

      {:ok, response} =
        Api.get("http://localhost:#{FakeServer.port()}/echo-headers",
          "X-Wumpex-Test-Header": "passed"
        )

      assert %{
               "x-wumpex-test-header" => "passed"
             } = response.headers
    end
  end
end
