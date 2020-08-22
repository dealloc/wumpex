defmodule Wumpex.Resource.Embed.AuthorTest do
  use ExUnit.Case

  doctest Wumpex.Resource.Embed.Author

  alias Wumpex.Resource.Embed.Author

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{"name" => "dealloc", "url" => "https://dealloc.dev"}

      assert %Author{
               name: "dealloc",
               url: "https://dealloc.dev"
             } = Author.to_struct(example)
    end
  end
end
