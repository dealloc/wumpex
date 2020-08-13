defmodule Wumpex.Resource.UserFlags do
  @moduledoc """
  Struct representing the flags a user account can have.
  """

  use Bitwise

  @type t :: %__MODULE__{
          none: boolean(),
          discord_employee: boolean(),
          discord_partner: boolean(),
          hypesquad_events: boolean(),
          bug_hunter_level_1: boolean(),
          house_bravery: boolean(),
          house_brilliance: boolean(),
          house_balance: boolean(),
          early_supporter: boolean(),
          team_user: boolean(),
          system: boolean(),
          bug_hunter_level_2: boolean(),
          verified_bot: boolean(),
          verified_bot_developer: boolean()
        }

  defstruct [
    :none,
    :discord_employee,
    :discord_partner,
    :hypesquad_events,
    :bug_hunter_level_1,
    :house_bravery,
    :house_brilliance,
    :house_balance,
    :early_supporter,
    :team_user,
    :system,
    :bug_hunter_level_2,
    :verified_bot,
    :verified_bot_developer
  ]

  @spec to_struct(data :: non_neg_integer()) :: t()
  def to_struct(data) when is_number(data) do
    %__MODULE__{
      none: data == 0,
      discord_employee: (data &&& 1 <<< 0) == 1 <<< 0,
      discord_partner: (data &&& 1 <<< 1) == 1 <<< 1,
      hypesquad_events: (data &&& 1 <<< 2) == 1 <<< 2,
      bug_hunter_level_1: (data &&& 1 <<< 3) == 1 <<< 3,
      house_bravery: (data &&& 1 <<< 6) == 1 <<< 6,
      house_brilliance: (data &&& 1 <<< 7) == 1 <<< 7,
      house_balance: (data &&& 1 <<< 8) == 1 <<< 8,
      early_supporter: (data &&& 1 <<< 9) == 1 <<< 9,
      team_user: (data &&& 1 <<< 10) == 1 <<< 10,
      system: (data &&& 1 <<< 12) == 1 <<< 12,
      bug_hunter_level_2: (data &&& 1 <<< 14) == 1 <<< 14,
      verified_bot: (data &&& 1 <<< 16) == 1 <<< 16,
      verified_bot_developer: (data &&& 1 <<< 17) == 1 <<< 17
    }
  end
end
