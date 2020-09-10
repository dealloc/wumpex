defmodule Wumpex do
  @moduledoc """
  Documentation for `Wumpex`.
  """

  @doc """
  Fetch the bot key from configuration.

      iex> Wumpex.token()
      "DUMMY-TEST-TOKEN"
  """
  @spec token() :: String.t() | nil
  def token do
    case Application.get_env(:wumpex, :key, nil) do
      token when is_nil(token) or is_binary(token) ->
        token

      token ->
        raise "Invalid key #{inspect(token)} configured!"
    end
  end
end
