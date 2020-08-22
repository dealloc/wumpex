defmodule Wumpex.Resource.Activity do
  @moduledoc """
  Represents the activity of a presence update in Discord.

  See the official [Discord documentation](https://discord.com/developers/docs/topics/gateway#activity-object).
  """

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

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:name` - the activity's name
  * `:type` - the `t:activity_type/0` activity type.
  * `:url` - stream URL, is validated when `:type` is `1`.
  * `:created_at` - unix timestamp of when the activity was added to the user's session.
  * `:timestamps` - unix `t:TWumpex.Resource.Timestamps.t/0` for start and end of the game.
  * `:application_id` - application id for the game.
  * `:details` - what the player is currently doing.
  * `:state` - the user's current party status.
  * `:emoji` - the emoji used for a custom status.
  * `:party` - information for the current party of the player.
  * `:assets` - images for the presence and their hover texts.
  * `:secrets` - secrets for Rich Presence joining and spectating.
  * `:instance` - whether or not the activity is an instance game session.
  * `:flags` - `t:Wumpex.Resource.Activity.Flags.t/0` describes what the payload includes.
  """
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

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Activity.to_struct(%{})
      %Wumpex.Resource.Activity{
        application_id: nil,
        assets: nil,
        created_at: nil,
        details: nil,
        emoji: nil,
        flags: nil,
        instance: nil,
        name: nil,
        party: nil,
        secrets: nil,
        state: nil,
        timestamps: nil,
        type: nil,
        url: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Activity.to_struct(%{"name" => "the name of the activity"})
      %Wumpex.Resource.Activity{
        name: "the name of the activity"
      }
  """
  @spec to_struct(data :: map()) :: t()
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
