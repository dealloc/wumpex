defmodule Wumpex.Resource.Channel.Overwrite do
  @moduledoc """
  Represents a set of overrides of permissions.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/permissions#permissions).
  """

  import Wumpex.Resource

  alias Wumpex.Resource

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          type: type(),
          allow: String.t(),
          deny: String.t()
        }

  @typedoc """
  The type of permission set. Can be either `"role"` or `"member"`.
  """
  @type type :: String.t()

  defstruct [
    :id,
    :type,
    :allow,
    :deny
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Channel.Overwrite.to_struct(%{})
      %Wumpex.Resource.Channel.Overwrite{
        id: nil,
        type: nil,
        allow: nil,
        deny: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Channel.Overwrite.to_struct(%{"id" => "155117677105512449", "type" => "role", "allow" => "0", "deny" => "0"})
      %Wumpex.Resource.Channel.Overwrite{
        id: "155117677105512449",
        type: "role",
        allow: "0",
        deny: "0"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    struct(__MODULE__, to_atomized_map(data))
  end
end
