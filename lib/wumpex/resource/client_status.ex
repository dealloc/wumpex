defmodule Wumpex.Resource.ClientStatus do
  import Wumpex.Resource

  @typedoc """
  Can be 	either "idle", "dnd", "online", or "offline"
  """
  @type status :: String.t()

  @type t :: %__MODULE__{
    desktop: status(),
    mobile: status(),
    web: status()
  }

  defstruct [
    :desktop,
    :mobile,
    :web
  ]

  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct!(__MODULE__, data)
  end
end
