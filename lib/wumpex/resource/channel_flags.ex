defmodule Wumpex.Resource.ChannelFlags do
  use Bitwise

  @type t :: %__MODULE__{
    suppress_join_notifications: boolean(),
    suppress_premium_subscriptions: boolean()
  }

  defstruct [
    :suppress_join_notifications,
    :suppress_premium_subscriptions
  ]

  @spec to_struct(data :: non_neg_integer()) :: t()
  def to_struct(data) when is_number(data) do
    %__MODULE__{
      suppress_join_notifications: (data &&& 1 <<< 0) == 1 <<< 0,
      suppress_premium_subscriptions: (data &&& 1 <<< 1) == 1 <<< 1,
    }
  end
end
