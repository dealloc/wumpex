defmodule Wumpex do
  @moduledoc """
  Documentation for `Wumpex`.
  """

  alias Wumpex.Api.Ratelimit

  @typedoc """
  Represents the identifier of a shard.

  See `Wumpex.Sharding`, `Wumpex.Gateway` and the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#sharding) for more information.
  """
  @type shard :: {non_neg_integer(), non_neg_integer()}

  @typedoc """
  Represents a guild identifier.
  """
  @type guild :: pos_integer() | String.t()

  @typedoc """
  Represents a channel identifier.
  """
  @type channel :: pos_integer() | String.t()

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

  @doc """
  Fetch the user ID.

  The first time this method is called it will execute an API call.
  """
  @spec user_id() :: String.t()
  def user_id do
    case Application.get_env(:wumpex, :user_id, nil) do
      nil ->
        load_user_id()

      token when is_integer(token) ->
        token
    end
  end

  defp load_user_id do
    {:ok,
     %{
       body: %{
         "id" => bot_id
       }
     }} = Ratelimit.request({:get, "/users/@me", "", [], []}, {:user, :me})

    Application.put_env(:wumpex, :user_id, bot_id)
    bot_id
  end
end
