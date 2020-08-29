defmodule Wumpex.Resource.Activity.SecretsTest do
  @moduledoc false
  use ExUnit.Case

  doctest Wumpex.Resource.Activity.Secrets

  alias Wumpex.Resource.Activity.Secrets

  describe "to_struct/1 should" do
    test "parse valid structs" do
      example = %{
        "join" => "join-value",
        "spectate" => "spectate-value",
        "match" => "match value"
      }

      assert %Secrets{
               join: "join-value",
               spectate: "spectate-value",
               match: "match value"
             } = Secrets.to_struct(example)
    end

    test "ignore missing fields" do
      assert %Secrets{
               join: nil,
               spectate: nil,
               match: nil
             } = Secrets.to_struct(%{})
    end
  end
end
