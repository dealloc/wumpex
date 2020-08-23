defmodule Wumpex.Resource.ClientStatus do
  @moduledoc """
  Represents the status of a client on the three available platforms.

  > Active sessions are indicated with an "online", "idle", or "dnd" string per platform.
  > If a user is offline or invisible, the corresponding field is not present.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#client-status-object).
  """

  import Wumpex.Resource

  @typedoc """
  Can be 	either "idle", "dnd", "online", or "offline"
  """
  @type status :: String.t()

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:desktop` - The user's status set for an active desktop (Windows, Linux, Mac) application session.
  * `:mobile` - The user's status set for an active mobile (iOS, Android) application session.
  * `:web` - The user's status set for an active web (browser, bot account) application session.
  """
  @type t :: %__MODULE__{
          desktop: status(),
          mobile: status(),
          web: status()
        }

  defstruct [
    :desktop,
    :mobile,
    :web
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.ClientStatus.to_struct(%{})
      %Wumpex.Resource.ClientStatus{
        desktop: nil,
        mobile: nil,
        web: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
