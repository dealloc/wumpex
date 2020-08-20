defmodule Wumpex.Resource.EmbedTest do
  use ExUnit.Case
  alias Wumpex.Resource.Embed

  describe "to_struct/1 should" do
    test "parse an example for embed" do
      example = %{
          "color" => 7_506_394,
          "description" => "Description 1",
          "title" => "Title 1",
          "type" => "rich"
      }

      assert %Embed{
        color: 7_506_394,
        description: "Description 1",
        title: "Title 1",
        type: "rich"
      } = Embed.to_struct(example)
    end
  end
end
