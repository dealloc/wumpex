defmodule Wumpex do
  @moduledoc """
  Documentation for `Wumpex`.
  """

  @doc """
  Fetch the bot key from configuration.
  """
  @spec token() :: String.t() | nil
  def token do
    case Application.get_env(:wumpex, :key) do
      token when is_nil(token) or is_binary(token) ->
        token

      _token ->
        raise "Invalid key configured!"
    end
  end
end
