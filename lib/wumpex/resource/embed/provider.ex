defmodule Wumpex.Resource.Embed.Provider do
  @moduledoc """
  Contains information about the provider of the `Wumpex.Resource.Embed`.
  """

  import Wumpex.Resource

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:name` - The name of the provider.
  * `:url` - The URL of the provider.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t()
        }

  defstruct [
    :name,
    :url
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.Provider.to_struct(%{})
      %Wumpex.Resource.Embed.Provider{
        name: nil,
        url: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.Provider.to_struct(%{"name" => "dealloc", "url" => "https://dealloc.dev"})
      %Wumpex.Resource.Embed.Provider{
        name: "dealloc",
        url: "https://dealloc.dev"
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data = to_atomized_map(data)
    struct(__MODULE__, data)
  end
end
