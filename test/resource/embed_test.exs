defmodule Wumpex.Resource.EmbedTest do
  use ExUnit.Case

  alias Wumpex.Resource.Embed
  alias Wumpex.Resource.Embed.Footer
  alias Wumpex.Resource.Embed.Author

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

    test "parse a full example for embed" do
      example =  %{
        "author" => %{},
        "color" => 1_853_403,
        "description" => "Description",
        "footer" => %{},
        "timestamp" => "2020-12-12T11:12:00+00:00",
        "title" => "Title",
        "type" => "rich",
        "url" => "https://www.youtube.com/watch?v=oHg5SJYRHA0"
      }

      assert %Embed{
        author: %Author{},
        color: 1_853_403,
        description: "Description",
        footer: %Footer{},
        timestamp: ~U[2020-12-12 11:12:00Z],
        title: "Title",
        type: "rich",
        url: "https://www.youtube.com/watch?v=oHg5SJYRHA0"
      } = Embed.to_struct(example)
    end
  end
end
