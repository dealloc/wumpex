defmodule Wumpex.Resource.Guild do
  @moduledoc """
  > Guilds in Discord represent an isolated collection of users and channels, and are often referred to as "servers" in the UI.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/guild).
  """

  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Channel
  alias Wumpex.Resource.Emoji
  alias Wumpex.Resource.Guild.ChannelFlags
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

  Can have the following values:
  * `0` - None
  * `1` - Tier 1
  * `2` - Tier 2
  * `3` - Tier 3
  """
  @type premium_tier :: 0 | 1 | 2 | 3

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:id` - The guild ID.
  * `:name` - The guild name (2 - 100 characters, excluding trailing and leading whitespace).
  * `:icon` - The icon hash.
  * `:splash` - The splash hash.
  * `:discovery_splash` - The discovery splash hash (only present for guilds with the `"DISCOVERABLE"` feature).
  * `:owner` - true if the user is the owner of the guild.
  * `:owner_id` - The ID of the owner.
  * `:permissions` - (legacy) total permissions of the user in the guild (excluding overrides).
  * `:permissions_new` - Total permissions of the user in the guild (excluding overrides).
  * `:region` - The voice region (ID) of the guild.
  * `:afk_channel_id` - The ID of the AFk channel.
  * `:afk_timeout` - The AFK timeout (in seconds).
  * `:embed_enabled` - **deprecated**, use `widget_enabled` instead).
  * `:embed_channel_id` - **deprecated**, use `widget_channel_id` instead.
  * `:verification_level` - The `t:verification_level/0` required for the guild.
  * `:default_message_notifications` - The default `t:message_notifications_level/0`.
  * `:explicit_content_filter` - The `t:explicit_content_filter_level/0`.
  * `:roles` - An array of the `Wumpex.Resource.Role` in the guild.
  * `:emojis` - Custom guild emojis.
  * `:features` - A list of enabled guild features.
  * `:mfa_level` - The MFA level for this guild.
  * `:application_id` - The application ID of the guild creator, if it's bot-created.
  * `:widget_enabled` - Set to `true` if the server widget is enabled.
  * `:widget_channel_id` - The channel ID that the widget will generate an invite to, or null if set to no invite.
  * `:system_channel_id` - The ID of the channel where guild notices such as welcome and boost evens are posted.
  * `:system_channel_flags` - The `Wumpex.Resource.Guild.ChannelFlags` for the guild.
  * `:rules_channel_id` - The ID of the channel where guilds with the `"PUBLIC"` feature can display rules and/or guidelines.
  * `:joined_at` - When this guild was joined.
  * `:large` - Whether this guild is considered large.
  * `:unavailable` - Whether this guild is unavailable due to an outage.
  * `:member_count` - Total number of members in this guild.
  * `:voice_states` - Voice states of members curretly in voice channels (without the `guild_id` key).
  * `:members` - An array of `Wumpex.Resource.Guild.Member` objects representing the users in the guild.
  * `:channels` - A list of `Wumpex.Resource.Channel` objects representing the channels in the guild.
  * `:presences` - Presences of the members in the guild, will only include non-offline mbmers if the size is greater than `large treshold`.
  * `:max_presences` - The maximum number of presences for the guild (default value, currently 25000, is in effect when `null` is returned).
  * `:max_members` - The maximum number of members for the guild.
  * `:vanity_url_code` - The vanity URL code for the guild.
  * `:description` - The description for the guild, if discoverable.
  * `:banner` - The banner hash.
  * `:premium_tier` - The server boost level (premium level).
  * `:premium_subscription_count` - The number of boosts this guild currently has.
  * `:preferred_locale` - The preferred locale of a guild with the `"PUBLIC"` feature, used in server discovery and notices from Discord (defaults to `"en-US"`).
  * `:pubic_updates_channel_id` - The ID of the channel where admins and moderators of guilds with the `"PUBLIC"` feature receive notices from Discord.
  * `:max_video_channel_users` - The maximum amount of users in a video channel.
  * `:approximate_member_count` - The approximate number of members in this guild, returned from the get guilds endpoint (when passing `with_counts` set to true).
  * `:approximate_presence_count` - Approximate number of non-offline members in this guild, returned from the get guilds endpoint (when passing `with_counts` set to true).
  """
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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Guild.to_struct(%{})
      %Wumpex.Resource.Guild{}
  """
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
