defmodule Wumpex.Resource.Message.Reaction do
  @moduledoc """
  Represents a reaction to a message.

  See the official [Discord documentation](https://discord.com/developers/docs/resources/channel#reaction-object).
  """

  import Wumpex.Resource

  alias Wumpex.Resource.Emoji

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:count` - The amount of times this emoji has been used to react to the message.
  * `:me` - Whether the current user has used this emoji to react to the message.
  * `:emoji` - The emoji this reaction represents.
  """
  @type t :: %__MODULE__{
          count: non_neg_integer(),
          me: boolean(),
          emoji: Emoji.t()
        }

  defstruct [
    :count,
    :me,
    :emoji
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Message.Reaction.to_struct(%{})
      %Wumpex.Resource.Message.Reaction{
        count: nil,
        me: nil,
        emoji: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Message.Reaction.to_struct(%{"count" => 1, "me" => true, "emoji" => %{}})
      %Wumpex.Resource.Message.Reaction{
        count: 1,
        me: true,
        emoji: %Wumpex.Resource.Emoji{}
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:emoji, nil, &Emoji.to_struct/1)

    struct(__MODULE__, data)
  end
end
