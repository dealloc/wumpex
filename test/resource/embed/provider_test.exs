defmodule Wumpex.Resource.Embed.ProviderTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Embed.Provider

  alias Wumpex.Resource.Embed.Provider

  describe "to_struct/1 should" do
    test "parse an example for an embed provider" do
      example = %{
        "name" => "dealloc",
        "url" => "https://dealloc.dev"
      }

      assert %Provider{
               name: "dealloc",
               url: "https://dealloc.dev"
             } = Provider.to_struct(example)
    end
  end
end
