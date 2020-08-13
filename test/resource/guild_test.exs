defmodule Wumpex.Resource.GuildTest do
  use ExUnit.Case

  alias Wumpex.Resource.ChannelFlags
  alias Wumpex.Resource.Guild

  describe "to_struct/1 should" do
    test "parse the official example for guild" do
      example = %{
        "widget_channel_id" => nil,
        "system_channel_id" => nil,
        "premium_tier" => 3,
        "system_channel_flags" => 0,
        "discovery_splash" => nil,
        "application_id" => nil,
        "owner_id" => "73193882359173120",
        "banner" => "9b6439a7de04f1d26af92f84ac9e1e4a",
        "features" => ["ANIMATED_ICON", "VERIFIED", "NEWS", "VANITY_URL",
         "DISCOVERABLE", "MORE_EMOJI", "INVITE_SPLASH", "BANNER", "PUBLIC"],
        "id" => "197038439483310086",
        "public_updates_channel_id" => "281283303326089216",
        "verification_level" => 3,
        "roles" => [],
        "embed_channel_id" => nil,
        "splash" => nil,
        "afk_timeout" => 300,
        "vanity_url_code" => "discord-testers",
        "icon" => "f64c482b807da4f539cff778d174971c",
        "emojis" => [],
        "preferred_locale" => "en-US",
        "region" => "us-west",
        "explicit_content_filter" => 2,
        "rules_channel_id" => "441688182833020939",
        "default_message_notifications" => 1,
        "name" => "Discord Testers",
        "max_members" => 250_000,
        "widget_enabled" => true,
        "description" => "The official place to report Discord Bugs!",
        "embed_enabled" => true,
        "premium_subscription_count" => 33,
        "mfa_level" => 1,
        "afk_channel_id" => nil,
        "max_presences" => 40_000
      }
      assert %Guild{
        id: "197038439483310086",
        name: "Discord Testers",
        icon: "f64c482b807da4f539cff778d174971c",
        description: "The official place to report Discord Bugs!",
        splash: nil,
        discovery_splash: nil,
        features: [
          "ANIMATED_ICON",
          "VERIFIED",
          "NEWS",
          "VANITY_URL",
          "DISCOVERABLE",
          "MORE_EMOJI",
          "INVITE_SPLASH",
          "BANNER",
          "PUBLIC"
        ],
        emojis: [],
        banner: "9b6439a7de04f1d26af92f84ac9e1e4a",
        owner_id: "73193882359173120",
        application_id: nil,
        region: "us-west",
        afk_channel_id: nil,
        afk_timeout: 300,
        system_channel_id: nil,
        widget_enabled: true,
        widget_channel_id: nil,
        verification_level: 3,
        roles: [],
        default_message_notifications: 1,
        mfa_level: 1,
        explicit_content_filter: 2,
        max_presences: 40_000,
        max_members: 250_000,
        vanity_url_code: "discord-testers",
        premium_tier: 3,
        premium_subscription_count: 33,
        system_channel_flags: %ChannelFlags{},
        preferred_locale: "en-US",
        rules_channel_id: "441688182833020939",
        public_updates_channel_id: "281283303326089216",
        embed_enabled: true,
        embed_channel_id: nil
        } = Guild.to_struct(example)
    end

    test "parse unavailable guilds" do
      example = %{
        "id" => "41771983423143937",
        "unavailable" => true
      }

      assert %Guild{
        id: "41771983423143937",
        unavailable: true
      } = Guild.to_struct(example)
    end
  end
end
