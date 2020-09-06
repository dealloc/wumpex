defmodule WebServerHelper do
  @moduledoc false
  use Cauldron

  def start_link do
    Cauldron.start_link(__MODULE__, port: 8081)
  end

  def handle("GET", %URI{path: "/no-ratelimit"}, req) do
    Request.reply(req, 200, "{}")
  end

  def handle("GET", %URI{path: "/passing-ratelimit"}, req) do
    Request.reply(req, 200, %{
      "retry-after" => 0,
      "x-ratelimit-remaining" => 5,
      "x-ratelimit-reset" => :os.system_time(:millisecond) + 1_000.50
    }, "{}")
  end

  def handle("GET", %URI{path: "/failing-ratelimit"}, req) do
    Request.reply(req, 429, %{
      "retry-after" => 1_000,
      "x-ratelimit-remaining" => 0,
      "x-ratelimit-reset" => :os.system_time(:millisecond) + 1_000.50
    }, "{}")
  end

  def handle("GET", %URI{path: "/json-body"}, req) do
    Request.reply(req, 200, "{\"hello\": \"world\"}")
  end

  def handle("GET", %URI{path: "/empty-body"}, req) do
    Request.reply(req, 200, "")
  end

  def handle("GET", %URI{path: "/echo-headers"}, req) do
    Request.reply(req, 200, req.headers, "")
  end
end
