defmodule Wumpex.Resource.ChannelTest do
  use ExUnit.Case

  alias Wumpex.Resource.Channel
  alias Wumpex.Resource.User

  describe "to_struct/1 should" do
    test "parse the official example for guild text channel" do
      example = %{
        "id" => "41771983423143937",
        "guild_id" => "41771983423143937",
        "name" => "general",
        "type" => 0,
        "position" => 6,
        "permission_overwrites" => [],
        "rate_limit_per_user" => 2,
        "nsfw" => true,
        "topic" => "24/7 chat about how to gank Mike #2",
        "last_message_id" => "155117677105512449",
        "parent_id" => "399942396007890945"
      }

      assert Channel.to_struct(example) == %Channel{
               id: "41771983423143937",
               guild_id: "41771983423143937",
               name: "general",
               type: 0,
               position: 6,
               permission_overwrites: [],
               rate_limit_per_user: 2,
               nsfw: true,
               topic: "24/7 chat about how to gank Mike #2",
               last_message_id: "155117677105512449",
               parent_id: "399942396007890945"
             }
    end

    test "parse the official example for guild news channel" do
      example = %{
        "id" => "41771983423143937",
        "guild_id" => "41771983423143937",
        "name" => "important-news",
        "type" => 5,
        "position" => 6,
        "permission_overwrites" => [],
        "nsfw" => true,
        "topic" => "Rumors about Half Life 3",
        "last_message_id" => "155117677105512449",
        "parent_id" => "399942396007890945"
      }

      assert Channel.to_struct(example) == %Channel{
               id: "41771983423143937",
               guild_id: "41771983423143937",
               name: "important-news",
               type: 5,
               position: 6,
               permission_overwrites: [],
               nsfw: true,
               topic: "Rumors about Half Life 3",
               last_message_id: "155117677105512449",
               parent_id: "399942396007890945"
             }
    end

    test "parse the official example for DM Channel" do
      example = %{
        "last_message_id" => "3343820033257021450",
        "type" => 1,
        "id" => "319674150115610528",
        "recipients" => [
          %{
            "username" => "test",
            "discriminator" => "9999",
            "id" => "82198898841029460",
            "avatar" => "33ecab261d4681afa4d85a04691c4a01"
          }
        ]
      }

      assert %Channel{
               last_message_id: "3343820033257021450",
               type: 1,
               id: "319674150115610528",
               recipients: [%User{}]
             } = Channel.to_struct(example)
    end

    test "parse the official example for Group DM Channel" do
      example = %{
        "name" => "Some test channel",
        "icon" => nil,
        "recipients" => [
          %{
            "username" => "test",
            "discriminator" => "9999",
            "id" => "82198898841029460",
            "avatar" => "33ecab261d4681afa4d85a04691c4a01"
          },
          %{
            "username" => "test2",
            "discriminator" => "9999",
            "id" => "82198810841029460",
            "avatar" => "33ecab261d4681afa4d85a10691c4a01"
          }
        ],
        "last_message_id" => "3343820033257021450",
        "type" => 3,
        "id" => "319674150115710528",
        "owner_id" => "82198810841029460"
      }

      assert %Channel{
               name: "Some test channel",
               icon: nil,
               recipients: [%User{}, %User{}],
               last_message_id: "3343820033257021450",
               type: 3,
               id: "319674150115710528",
               owner_id: "82198810841029460"
             } = Channel.to_struct(example)
    end

    test "parse the official example for channel category" do
      example = %{
        "permission_overwrites" => [],
        "name" => "Test",
        "parent_id" => nil,
        "nsfw" => false,
        "position" => 0,
        "guild_id" => "290926798629997250",
        "type" => 4,
        "id" => "399942396007890945"
      }

      assert Channel.to_struct(example) == %Channel{
               permission_overwrites: [],
               name: "Test",
               parent_id: nil,
               nsfw: false,
               position: 0,
               guild_id: "290926798629997250",
               type: 4,
               id: "399942396007890945"
             }
    end

    test "parse the official example for store channel" do
      example = %{
        "id" => "41771983423143937",
        "guild_id" => "41771983423143937",
        "name" => "buy dota-2",
        "type" => 6,
        "position" => 0,
        "permission_overwrites" => [],
        "nsfw" => false,
        "parent_id" => nil
      }

      assert Channel.to_struct(example) == %Channel{
               id: "41771983423143937",
               guild_id: "41771983423143937",
               name: "buy dota-2",
               type: 6,
               position: 0,
               permission_overwrites: [],
               nsfw: false,
               parent_id: nil
             }
    end
  end
end
