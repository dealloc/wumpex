defmodule Wumpex.Resource.Embed.VideoTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Embed.Video

  alias Wumpex.Resource.Embed.Video

  describe "to_struct/1 should" do
    test "parse an example for an embed provider" do
      example = %{
        "url" => "https://dealloc.dev",
        "height" => 100,
        "width" => 50
      }

      assert %Video{
               url: "https://dealloc.dev",
               height: 100,
               width: 50
             } = Video.to_struct(example)
    end
  end
end
