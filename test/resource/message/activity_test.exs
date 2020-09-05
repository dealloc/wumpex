defmodule Wumpex.Resource.Message.ActivityTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Message.Activity

  alias Wumpex.Resource.Message.Activity

  describe "to_struct/1 should" do
    test "parse example" do
      example = %{
        "type" => 1,
        "party_id" => "12345"
      }

      assert %Activity{
               type: 1,
               party_id: "12345"
             } = Activity.to_struct(example)
    end
  end
end
