defmodule Wumpex.Resource.UserTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.User

  alias Wumpex.Resource.User

  describe "to_struct/1 should" do
    test "parse the official example" do
      example = %{
        "avatar" => "33ecab261d4681afa4d85a04691c4a01",
        "discriminator" => "9999",
        "id" => "82198898841029460",
        "username" => "test"
      }

      assert %User{
               avatar: "33ecab261d4681afa4d85a04691c4a01",
               discriminator: "9999",
               id: "82198898841029460",
               username: "test"
             } = User.to_struct(example)
    end
  end
end
