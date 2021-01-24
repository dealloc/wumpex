defmodule Wumpex.Voice.OpcodesTest do
  @moduledoc false
  use ExUnit.Case

  alias Wumpex.Voice.Opcodes

  doctest Wumpex.Voice.Opcodes

  describe "speaking/2 should" do
    test "raise on unknown options" do
      assert_raise(CaseClauseError, fn ->
        Opcodes.speaking(0, [:does_not_work])
      end)
    end
  end
end
