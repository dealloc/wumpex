defmodule Wumpex.Resource.Embed.Field do
  @moduledoc """
  Contains information about custom fields in an `Wumpex.Resource.Embed`.
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:name` - The name of the field.
  * `:value` - The value of the field.
  * `:inline` whether or not this field should display inline.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          inline: boolean()
        }

  defstruct [
    :name,
    :value,
    :inline
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Field.to_struct(%{})
      %Wumpex.Resource.Embed.Field{
        name: nil,
        value: nil,
        inline: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Field.to_struct(%{"name" => "dealloc", "value" => "https://dealloc.dev", "inline" => true})
      %Wumpex.Resource.Embed.Field{
        name: "dealloc",
        value: "https://dealloc.dev",
        inline: true
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)

    struct(__MODULE__, data)
  end
end
