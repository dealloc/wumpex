defmodule Wumpex.Resource do
  @moduledoc """
  Base module for so called "resources" (as the [discord documentation](https://discord.com/developers/docs) refers to them).

  Resources are mainly used in the context of the HTTP API, but the gateway shares a lot of these types (so we use the same there).
  """

  @typedoc """
  Represents a uniquely identifiable descriptor, guaranteed to be unique across all of Discord.

  See the official [Discord documentation](https://discord.com/developers/docs/reference#snowflakes).
  """
  @type snowflake :: String.t()

  @doc """
  Attempts to convert a given string into an (existing!) `t:atom/0`.

  This uses `String.to_existing_atom/1` under the hood, so passing a non-existing atom will cause an ArgumentError

  ### Examples

      iex> Wumpex.Resource.to_atom!("known")
      :known

      iex> Wumpex.Resource.to_atom!("cannot-exist")
      ** (ArgumentError) argument error
  """
  @spec to_atom!(value :: String.t() | atom()) :: atom()
  def to_atom!(value) when is_atom(value), do: value
  def to_atom!(value) when is_binary(value), do: String.to_existing_atom(value)

  @doc """
  Attempts to convert a given string into a `t:DateTime.t/0` instance.

  ### Examples

      iex> Wumpex.Resource.to_datetime("2017-07-11T17:27:07.299000+00:00")
      ~U[2017-07-11 17:27:07.299000Z]

      iex> Wumpex.Resource.to_datetime(0)
      ~U[1970-01-01 00:00:00.000Z]

      iex> Wumpex.Resource.to_datetime(~U[2020-07-11 17:27:07.299000Z])
      ~U[2020-07-11 17:27:07.299000Z]
  """
  @spec to_datetime(value :: DateTime.t() | nil | String.t()) :: DateTime.t() | nil
  def to_datetime(%DateTime{} = value), do: value
  def to_datetime(nil), do: nil

  def to_datetime(value) when is_number(value) do
    {:ok, result} = DateTime.from_unix(value, :millisecond)

    result
  end

  def to_datetime(value) do
    {:ok, result, _offset} = DateTime.from_iso8601(value)

    result
  end

  @doc """
  Transforms a map with strings for keys into a map with atoms for keys.

  ### Example

      iex> Wumpex.Resource.to_atomized_map(%{"hello" => "world"})
      %{hello: "world"}
  """
  @spec to_atomized_map(value :: map()) :: map()
  def to_atomized_map(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {to_atom!(k), v} end)
  end

  @doc """
  Maps a list of resources to the given module struct.

  ### Example

      iex> Wumpex.Resource.to_structs([%{}], Wumpex.Resource.Role)
      [%Wumpex.Resource.Role{}]
  """
  @spec to_structs(values :: [map()], module :: module()) :: [map()]
  def to_structs(values, module) when is_list(values) and is_atom(module) do
    Enum.map(values, &module.to_struct/1)
  end
end
