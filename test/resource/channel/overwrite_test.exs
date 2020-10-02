defmodule Wumpex.Resource.Channel.OverwriteTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Channel.Overwrite

  alias Wumpex.Resource.Channel.Overwrite

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "id" => "155117677105512449",
        "type" => "role",
        "allow" => "0",
        "deny" => "0"
      }

      assert %Overwrite{
               id: "155117677105512449",
               type: "role",
               allow: "0",
               deny: "0"
             } = Overwrite.to_struct(example)
    end
  end
end
