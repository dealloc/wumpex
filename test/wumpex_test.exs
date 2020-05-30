defmodule WumpexTest do
  use ExUnit.Case
  doctest Wumpex

  test "greets the world" do
    assert Wumpex.hello() == :world
  end
end
