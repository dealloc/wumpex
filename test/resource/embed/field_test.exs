defmodule Wumpex.Resource.Embed.FieldTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Embed.Field

  alias Wumpex.Resource.Embed.Field

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "name" => "dealloc",
        "value" => "https://dealloc.dev",
        "inline" => true
      }

      assert %Field{
               name: "dealloc",
               value: "https://dealloc.dev",
               inline: true
             } = Field.to_struct(example)
    end
  end
end
