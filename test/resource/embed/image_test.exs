defmodule Wumpex.Resource.Embed.ImageTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Embed.Image

  alias Wumpex.Resource.Embed.Image

  describe "to_struct/1 should" do
    test "parse an example for embed image" do
      example = %{
        "url" => "https://google.com",
        "proxy_url" => "https://google.se",
        "height" => 10,
        "width" => 20,
      }

      assert %Image{
        url: "https://google.com",
        proxy_url: "https://google.se",
        height: 10,
        width: 20
      } = Image.to_struct(example)
    end
  end
end
