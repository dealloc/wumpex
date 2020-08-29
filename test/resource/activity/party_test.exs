defmodule Wumpex.Resource.Activity.PartyTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Activity.Party

  alias Wumpex.Resource.Activity.Party

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "id" => "308994132968210433",
        "size" => [20, 30]
      }

      assert %Party{
               id: "308994132968210433",
               size: {20, 30}
             } = Party.to_struct(example)
    end

    test "ignore missing fields" do
      assert %Party{
               id: nil,
               size: nil
             } = Party.to_struct(%{})
    end
  end
end
