defmodule Wumpex.Resource.User do
  @moduledoc """
  > Users in Discord are generally considered the base entity.
  > Users can spawn across the entire platform, be members of guilds, participate in text and voice chat, and much more.
  > Users are separated by a distinction of "bot" vs "normal".
  > Although they are similar, bot users are automated users that are "owned" by another user.
  > Unlike normal users, bot users do not have a limitation on the number of Guilds they can be a part of.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/user#users-resource).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.UserFlags

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The ID of the user.
  * `:username` - The user's username, not unique across the platform.
  * `:discriminator` - The user's 4 digit discord-tag.
  * `:avatar` - The user's avatar hash.
  * `:bot` - Whether the user belongs to an OAuth2 application.
  * `:system` - Whether the user is an official Discord system user (part of the urgent message system).
  * `:mfa_enabled` - Whether the user has two factor enabled on their account.
  * `:locale`- The user's preferred locale.
  * `:verified` - Whether the user's email has been verified.
  * `:email` - The user's email.
  * `:flags` - The flags on a user's account.
  * `:premium_type` - The type of Nitro subscription of the user.
  * `:public_flags` - The public flags on a user's account.
  * `:member` - Only passed when the user object was received through a `Wumpex.Resource.Message` object.
  """
  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          username: String.t(),
          discriminator: String.t(),
          avatar: String.t(),
          bot: boolean(),
          system: boolean(),
          mfa_enabled: boolean(),
          locale: String.t(),
          verified: boolean(),
          email: String.t(),
          flags: UserFlags.t(),
          premium_type: non_neg_integer(),
          public_flags: UserFlags.t(),
          # See https://discord.com/developers/docs/resources/channel#message-object-message-structure
          member: Member.t()
        }

  @typedoc """
  Premium types denote the level of premium a user has.

  Can have the following values:
  - `0` None
  - `1` Nitro Classic
  - `2` Nitro
  """
  @type premium_type :: 0 | 1 | 2

  defstruct [
    :id,
    :username,
    :discriminator,
    :avatar,
    :bot,
    :system,
    :mfa_enabled,
    :locale,
    :verified,
    :email,
    :flags,
    :premium_type,
    :public_flags,
    :member
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.User.to_struct(%{})
      %Wumpex.Resource.User{}
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:flags, nil, &UserFlags.to_struct/1)
      |> Map.update(:public_flags, nil, &UserFlags.to_struct/1)
      |> Map.update(:member, nil, &Member.to_struct/1)

    struct(__MODULE__, data)
  end
end
