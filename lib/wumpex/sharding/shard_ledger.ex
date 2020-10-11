defmodule Wumpex.Sharding.ShardLedger do
  @moduledoc """
  Keeps track of all active shards by their name.

  This module uses `Wumpex.Base.Ledger` under the hood.
  """
  use Wumpex.Base.Ledger
end
