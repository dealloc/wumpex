defmodule Wumpex.Resource.Activity.AssetsTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Activity.Assets

  alias Wumpex.Resource.Activity.Assets

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "large_image" => "308994132968210433",
        "large_text" => "Hover text for large",
        "small_image" => "308994132968210433_small",
        "small_text" => "Hover text for small"
      }

      assert %Assets{
               large_image: "308994132968210433",
               large_text: "Hover text for large",
               small_image: "308994132968210433_small",
               small_text: "Hover text for small"
             } = Assets.to_struct(example)
    end

    test "ignore missing fields" do
      assert %Assets{
               large_image: nil,
               large_text: nil,
               small_image: nil,
               small_text: nil
             } = Assets.to_struct(%{})
    end
  end
end
