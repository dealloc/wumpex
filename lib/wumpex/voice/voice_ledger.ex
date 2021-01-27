defmodule Wumpex.Voice.VoiceLedger do
  @moduledoc """
  Keeps track of all voice connections by their name.

  This module uses `Wumpex.Base.Ledger` under the hood.
  """

  use Wumpex.Base.Ledger
end
