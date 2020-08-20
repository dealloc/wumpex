defmodule Wumpex.Resource.User do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.UserFlags

  @typedoc """
  Premium types denote the level of premium a user has.

  Can have the following values:
  - `0` None
  - `1` Nitro Classic
  - `2` Nitro
  """
  @type premium_type :: 0 | 1 | 2

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
