defmodule Wumpex.Resource.Activity do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.Activity.Assets
  alias Wumpex.Resource.Activity.Emoji
  alias Wumpex.Resource.Activity.Flags
  alias Wumpex.Resource.Activity.Party
  alias Wumpex.Resource.Activity.Secrets
  alias Wumpex.Resource.Activity.Timestamps

  @typedoc """
  Represents the type of activity.

  Can contain the following values:
  | ID | Name      | Format              | Example                   |
  |----|-----------|---------------------|---------------------------|
  | 0  | Game      | Playing {name}      | "Playing Rocket League"   |
  | 1  | Streaming | Streaming {details} | "Streaming Rocket League" |
  | 2  | Listening | Listening to {name} | "Listening to Spotify"    |
  | 4  | Custom    | {emoji} {name}      | ":smiley: I am cool"      |
  """
  @type activity_type :: 0 | 1 | 2 | 4

  @type t :: %__MODULE__{
          name: String.t(),
          type: activity_type(),
          url: String.t(),
          created_at: DateTime.t(),
          timestamps: Timestamps.t(),
          application_id: Resource.snowflake(),
          details: String.t(),
          state: String.t(),
          emoji: Emoji.t(),
          party: Party.t(),
          assets: Assets.t(),
          secrets: Secrets.t(),
          instance: boolean(),
          flags: Flags.t()
        }

  defstruct [
    :name,
    :type,
    :url,
    :created_at,
    :timestamps,
    :application_id,
    :details,
    :state,
    :emoji,
    :party,
    :assets,
    :secrets,
    :instance,
    :flags
  ]

  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:created_at, nil, &to_datetime/1)
      |> Map.update(:timestamps, nil, &Timestamps.to_struct/1)
      |> Map.update(:emoji, nil, &Emoji.to_struct/1)
      |> Map.update(:party, nil, &Party.to_struct/1)
      |> Map.update(:assets, nil, &Assets.to_struct/1)
      |> Map.update(:secrets, nil, &Secrets.to_struct/1)
      |> Map.update(:flags, nil, &Flags.to_struct/1)

    struct(__MODULE__, data)
  end
end
