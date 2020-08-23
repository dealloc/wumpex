defmodule Wumpex.Resource.Message.ApplicationTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Message.Application

  alias Wumpex.Resource.Message.Application

  describe "to_struct/1 should" do
    test "parse example" do
      example = %{
        "id" => "73193882359173121",
        "cover_image" => "73193882359173122",
        "description" => "Description of app",
        "icon" => "73193882359173123",
        "name" => "name of app"
      }

      assert %Application{
        id: "73193882359173121",
        cover_image: "73193882359173122",
        description: "Description of app",
        icon: "73193882359173123",
        name: "name of app"
      } = Application.to_struct(example)
    end
  end
end
