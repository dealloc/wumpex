defmodule Wumpex.Resource.ClientStatusTest do
  use ExUnit.Case

  doctest Wumpex.Resource.ClientStatus

  alias Wumpex.Resource.ClientStatus

  describe "to_struct/1 should" do
    test "parse an example for a channel mention" do
      example = %{
        "desktop" => "online",
        "mobile" => "dnd",
        "web" => "offline"
      }

      assert %ClientStatus{
               desktop: "online",
               mobile: "dnd",
               web: "offline"
             } = ClientStatus.to_struct(example)
    end
  end
end
