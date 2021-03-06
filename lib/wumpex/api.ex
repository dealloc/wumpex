defmodule Wumpex.Api do
  @moduledoc """
  Wraps `HTTPoison` and configures it according to the Discord specifications.

  This module handles encoding outgoing requests, decoding incoming responses, adding the approperiate headers.
  """

  use HTTPoison.Base

  @impl HTTPoison.Base
  def process_url("http" <> _ = path), do: path

  def process_url(path),
    do: Application.get_env(:wumpex, :endpoint, "https://discord.com/api/v8") <> path

  @impl HTTPoison.Base
  def process_request_body(""), do: ""
  def process_request_body({:multipart, _list} = body), do: body
  def process_request_body(body), do: Jason.encode!(body)

  @impl HTTPoison.Base
  def process_request_headers(headers),
    do:
      Keyword.merge(
        [
          "user-agent": "Wumpex (https://github.com/dealloc/wumpex, 0.1.0)",
          "content-type": "application/json",
          authorization: "Bot #{Wumpex.token()}",
          "x-ratelimit-precision": "millisecond"
        ],
        headers
      )

  @impl HTTPoison.Base
  def process_response_body(""), do: ""
  def process_response_body(body), do: Jason.decode!(body)

  @impl HTTPoison.Base
  def process_response_headers(headers) do
    headers
    |> Map.new(fn {key, value} -> {String.downcase(key), value} end)
    |> Map.update("x-ratelimit-remaining", 999, &String.to_integer/1)
    # Transforms seconds with floating milliseconds to milliseconds (without floating).
    |> Map.update("x-ratelimit-reset", 0, &round(String.to_float(&1) * 1000))
  end
end
