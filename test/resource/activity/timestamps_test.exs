defmodule Wumpex.Resource.Activity.TimestampsTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Activity.Timestamps

  alias Wumpex.Resource.Activity.Timestamps

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "start" => 1_597_408_237_567,
        "end" => 1_597_408_257_097
      }

      assert %Timestamps{
               start: ~U[2020-08-14 12:30:37.567Z],
               end: ~U[2020-08-14 12:30:57.097Z]
             } = Timestamps.to_struct(example)
    end

    test "ignore missing fields" do
      assert %Timestamps{
               start: nil,
               end: nil
             } = Timestamps.to_struct(%{})
    end
  end
end
