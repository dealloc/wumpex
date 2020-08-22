defmodule Wumpex.Resource.Guild do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Channel
  alias Wumpex.Resource.ChannelFlags
  alias Wumpex.Resource.Emoji
  alias Wumpex.Resource.Guild.Member
  alias Wumpex.Resource.PresenceUpdate
  alias Wumpex.Resource.Role
  alias Wumpex.Resource.VoiceState

  @typedoc """
  Members of the server must meet the following criteria before they can send messages in text channels or initiate a direct message conversation.
  If a member has an assigned role this does nto apply.
  Discord recommends setting a verification level for a public guild.

  Can have the following values:
  - `0` (**NONE**) - Unrestricted.
  - `1` (**LOW**) - Must have verified email on account.
  - `2` (**MEDIUM**) - Must be registered on Discord for longer than 5 minutes.
  - `3` (**HIGH**) - (╯°□°）╯︵ ┻━┻ - must be a member of the server for longer than 10 minutes.
  - `4` (**VERY_HIGH**) - ┻━┻ ミヽ(ಠ 益 ಠ)ﾉ彡 ┻━┻ - must have a verified phone number.
  """
  @type verification_level :: 0 | 1 | 2 | 3 | 4

  @typedoc """
  This will determine whether members who have not explicitly set their notification settings receive a notification for every message sent in this server or not.

  Discord highly recommends setting this to only @mentions or `1` in the code, for a public Discord to avoid [this insanity](https://www.youtube.com/watch?v=zGl796352RI).

  Can have the following values:
  - `0` (**ALL_MESSAGES**) - All Messages
  - `1` (**ONLY_MENTIONS**) - Only **@mentions**
  """
  @type message_notifications_level :: 0 | 1

  @typedoc """
  Whether Discord will scan and automatically delete messages with explicit content.

  Can have the following values:
  - `0` (**DISABLED**) - Direct messages will not be scanned for explicit content.
  - `1` (**MEMBERS_WITHOUT_ROLES**) - Scan direct messages from everyone unless they are a friend.
  - `2` (**ALL_MEMBERS**) - Scan direct messages from everyone.
  """
  @type explicit_content_filter_level :: 0 | 1 | 2

  @typedoc """
  When enabled, this requires members with moderation powers to have two-factor authentication enabled on their account in order to take moderation actions (e.g. kick, ban, and delete message).
  This can help prevent malicious people who compromise a mod or admin's account from taking destructive actions.
  **This setting can only be changed by the server owner if they have 2FA enabled on their account.**

  Can have the following values:
  - `0` (**NONE**)
  - `1` (**ELEVATED**)
  """
  @type mfa_level :: 0 | 1

  @typedoc """
  server boost level

  TODO: docs
  """
  @type premium_tier :: 0 | 1 | 2 | 3

  @type t :: %__MODULE__{
          id: Resource.snowflake(),
          name: String.t(),
          icon: String.t(),
          splash: String.t(),
          discovery_splash: String.t(),
          owner: boolean(),
          owner_id: Resource.snowflake(),
          permissions: non_neg_integer(),
          permissions_new: non_neg_integer(),
          region: String.t(),
          afk_channel_id: Resource.snowflake(),
          afk_timeout: non_neg_integer(),
          embed_enabled: boolean(),
          embed_channel_id: Resource.snowflake(),
          verification_level: verification_level(),
          default_message_notifications: message_notifications_level(),
          explicit_content_filter: explicit_content_filter_level(),
          roles: [Role.t()],
          emojis: [Emoji.t()],
          features: [String.t()],
          mfa_level: non_neg_integer(),
          application_id: Resource.snowflake(),
          widget_enabled: boolean(),
          widget_channel_id: Resource.snowflake(),
          system_channel_id: Resource.snowflake(),
          system_channel_flags: ChannelFlags.t(),
          rules_channel_id: Resource.snowflake(),
          joined_at: DateTime.t(),
          large: boolean(),
          unavailable: boolean(),
          member_count: non_neg_integer(),
          voice_states: [VoiceState.t()],
          members: [Member.t()],
          channels: [Channel.t()],
          presences: [PresenceUpdate.t()],
          max_presences: non_neg_integer(),
          max_members: non_neg_integer(),
          vanity_url_code: String.t(),
          description: String.t(),
          banner: String.t(),
          premium_tier: premium_tier(),
          premium_subscription_count: non_neg_integer(),
          preferred_locale: String.t(),
          public_updates_channel_id: Resource.snowflake(),
          max_video_channel_users: non_neg_integer(),
          approximate_member_count: non_neg_integer(),
          approximate_presence_count: non_neg_integer()
        }

  defstruct [
    :id,
    :name,
    :icon,
    :splash,
    :discovery_splash,
    :owner,
    :owner_id,
    :permissions,
    :permissions_new,
    :region,
    :afk_channel_id,
    :afk_timeout,
    :embed_enabled,
    :embed_channel_id,
    :verification_level,
    :default_message_notifications,
    :explicit_content_filter,
    :roles,
    :emojis,
    :features,
    :mfa_level,
    :application_id,
    :widget_enabled,
    :widget_channel_id,
    :system_channel_id,
    :system_channel_flags,
    :rules_channel_id,
    :joined_at,
    :large,
    :unavailable,
    :member_count,
    :voice_states,
    :members,
    :channels,
    :presences,
    :max_presences,
    :max_members,
    :vanity_url_code,
    :description,
    :banner,
    :premium_tier,
    :premium_subscription_count,
    :preferred_locale,
    :public_updates_channel_id,
    :max_video_channel_users,
    :approximate_member_count,
    :approximate_presence_count
  ]

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:roles, nil, &to_structs(&1, Role))
      |> Map.update(:emojis, nil, &to_structs(&1, Emoji))
      |> Map.update(:system_channel_flags, nil, &ChannelFlags.to_struct/1)
      |> Map.update(:joined_at, nil, &to_datetime/1)
      |> Map.update(:voice_states, nil, &to_structs(&1, VoiceState))
      |> Map.update(:members, nil, &to_structs(&1, Member))
      |> Map.update(:channels, nil, &to_structs(&1, Channel))
      |> Map.update(:presences, nil, &to_structs(&1, PresenceUpdate))

    struct(__MODULE__, data)
  end
end
