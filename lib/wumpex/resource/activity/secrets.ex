defmodule Wumpex.Resource.Activity.Secrets do
  @moduledoc """
  Secrets for `t:Wumpex.Resource.PresenceUpdate.t/0` joining and spectating.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#activity-object-activity-secrets).
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:join` - the secret for joinoing a party.
  * `:spectate` - the secret for spectating a game.
  * `:match` - the secret for a specific instanced match.
  """
  @type t :: %__MODULE__{
          join: String.t(),
          spectate: String.t(),
          match: String.t()
        }

  defstruct [
    :join,
    :spectate,
    :match
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.Secrets.to_struct(%{})
      %Wumpex.Resource.Activity.Secrets{
        join: nil,
        spectate: nil,
        match: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.Secrets.to_struct(%{"join" => "join-secret", "spectate" => "spectate-secret"})
      %Wumpex.Resource.Activity.Secrets{
        join: "join-secret",
        spectate: "spectate-secret",
        match: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
