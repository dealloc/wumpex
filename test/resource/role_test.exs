defmodule Wumpex.Resource.RoleTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Role

  alias Wumpex.Resource.Role

  describe "to_struct/1 should" do
    test "parse the official example" do
      example = %{
        "id" => "41771983423143936",
        "name" => "WE DEM BOYZZ!!!!!!",
        "color" => 3_447_003,
        "hoist" => true,
        "position" => 1,
        "permissions" => "66321471",
        "managed" => false,
        "mentionable" => false
      }

      assert Role.to_struct(example) == %Role{
               id: "41771983423143936",
               name: "WE DEM BOYZZ!!!!!!",
               color: 3_447_003,
               hoist: true,
               position: 1,
               permissions: "66321471",
               managed: false,
               mentionable: false
             }
    end
  end
end
