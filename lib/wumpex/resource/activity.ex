defmodule Wumpex.Resource.Activity do
  import Wumpex.Resource

  alias Wumpex.Resource

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

  defmodule Timestamps do
    @type t :: %__MODULE__{
            start: DateTime.t(),
            end: DateTime.t()
          }

    defstruct [
      :start,
      :end
    ]

    @spec to_struct(data :: map()) :: t()
    def to_struct(data) when is_map(data) do
      data =
        data
        |> to_atomized_map()
        |> Map.update(:start, nil, &to_datetime/1)
        |> Map.update(:end, nil, &to_datetime/1)

        struct!(__MODULE__, data)
    end
  end

  defmodule Emoji do
    @type t :: %__MODULE__{
            name: String.t(),
            id: Resource.snowflake(),
            animated: boolean()
          }

    defstruct [
      :name,
      :id,
      :animated
    ]

    def to_struct(data) when is_map(data) do
      data = to_atomized_map(data)

      struct!(__MODULE__, data)
    end
  end

  defmodule Party do
    @type t :: %__MODULE__{
            id: String.t(),
            size: {non_neg_integer(), non_neg_integer()}
          }

    defstruct [
      :id,
      :size
    ]

    def to_struct(data) when is_map(data) do
      data =
        data
        |> to_atomized_map()
        |> Map.update(:size, nil, fn [current, max] -> {current, max} end)

      struct!(__MODULE__, data)
    end
  end

  defmodule Assets do
    @type t :: %__MODULE__{
      large_image: String.t(),
      large_text: String.t(),
      small_image: String.t(),
      small_text: String.t()
    }

    defstruct [
      :large_image,
      :large_text,
      :small_image,
      :small_text
    ]

    def to_struct(data) when is_map(data) do
      data = to_atomized_map(data)

      struct!(__MODULE__, data)
    end
  end

  defmodule Secrets do
    @type t :: %__MODULE__{
      join: String.t(),
      spectate: String.t(),
      match: String.t()
    }

    defstruct [
      :join,
      :spectate,
      :match
    ]

    def to_struct(data) when is_map(data) do
      data = to_atomized_map(data)

      struct!(__MODULE__, data)
    end
  end

  defmodule Flags do
    use Bitwise

    @type t :: %__MODULE__{
      instance: boolean(),
      join: boolean(),
      spectate: boolean(),
      join_request: boolean(),
      sync: boolean(),
      play: boolean(),
    }

    defstruct [
      :instance,
      :join,
      :spectate,
      :join_request,
      :sync,
      :play
    ]

    @spec to_struct(data :: non_neg_integer()) :: t()
    def to_struct(data) when is_number(data) do
      %__MODULE__{
        instance: (data &&& 1 <<< 0) == (1 <<< 0),
        join: (data &&& 1 <<< 1) == (1 <<< 1),
        spectate: (data &&& 1 <<< 2) == (1 <<< 2),
        join_request: (data &&& 1 <<< 3) == (1 <<< 3),
        sync: (data &&& 1 <<< 4) == (1 <<< 4),
        play: (data &&& 1 <<< 5) == (1 <<< 5)
      }
    end
  end

  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:created_at, nil, &to_datetime/1)
      |> Map.update(:timestamps, nil, &Timestamps.to_struct/1)
      |> Map.update(:emoji, nil, &Emoji.to_struct/1)
      |> Map.update(:party, nil, &Party.to_struct/1)
      |> Map.update(:assets, nil, &Assets.to_struct/1)
      |> Map.update(:secret, nil, &Secrets.to_struct/1)
      |> Map.update(:flags, nil, &Flags.to_struct/1)

    struct!(__MODULE__, data)
  end
end
