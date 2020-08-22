defmodule Wumpex.Resource.Embed.FooterTest do
use ExUnit.Case

doctest Wumpex.Resource.Embed.Footer

alias Wumpex.Resource.Embed.Footer

  describe "to_struct/1 should" do
    test "parse an example for footer" do
      example = %{
        "icon_url" => "http://lorempixel.com/400/200/",
        "proxy_icon_url" =>
          "https://images-ext-2.discordapp.net/external/-VyOqtinCm7v6Jr7VCgg9oDCAz_KutB655dIbCyjNFE/http/lorempixel.com/400/200/",
        "text" => "Footer text"
      }

      assert %Footer{
        icon_url: "http://lorempixel.com/400/200/",
        proxy_icon_url:
          "https://images-ext-2.discordapp.net/external/-VyOqtinCm7v6Jr7VCgg9oDCAz_KutB655dIbCyjNFE/http/lorempixel.com/400/200/",
        text: "Footer text"
      } = Footer.to_struct(example)
    end
  end
end
