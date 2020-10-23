defmodule Wumpex do
  @moduledoc """
  Documentation for `Wumpex`.
  """

  @typedoc """
  Represents the identifier of a shard.

  See `Wumpex.Sharding`, `Wumpex.Gateway` and the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#sharding) for more information.
  """
  @type shard :: {non_neg_integer(), non_neg_integer()}

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
