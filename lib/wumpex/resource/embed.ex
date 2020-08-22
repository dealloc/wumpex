defmodule Wumpex.Resource.Embed do
  import Wumpex.Resource

  alias Wumpex.Resource.Embed.Footer
  alias Wumpex.Resource.Embed.Image
  alias Wumpex.Resource.Embed.Thumbnail
  alias Wumpex.Resource.Embed.Video
  alias Wumpex.Resource.Embed.Provider
  alias Wumpex.Resource.Embed.Author
  alias Wumpex.Resource.Embed.Field

  @typedoc """
  Represents the struct form of this module.

  Contains the following fields:
  * `:title` - The title of the embed.
  * `:type` - The `t:type/0` of embed (soft deprecated).
  * `:description` - The description of the embed.
  * `:url` The URL of the embed.
  * `:timestamp` The `DateTime` of the embed.
  * `:color` - The colour code of the embed.
  * `:footer` - The `Wumpex.Resource.Embed.Footer` of the embed.
  * `:image` - The image of the embed.
  * `:thumbnail` - The thumbnail information of the embed.
  * `:video` The video information of the embed.
  * `:provider` - The provider information of the embed.
  * `:author` - The author information of the embed.
  * `:fields` - The custom fields information of the embed.
  """
  @type t :: %__MODULE__{
          title: String.t(),
          type: String.t(),
          description: String.t(),
          url: String.t(),
          timestamp: DateTime.t(),
          color: non_neg_integer(),
          footer: Footer.t(),
          image: Image.t(),
          thumbnail: Thumbnail.t(),
          video: Video.t(),
          provider: Provider.t(),
          author: Author.t(),
          fields: [Field.t()]
        }

  @typedoc """
  Represents the type of embed (always "rich" for webhook embeds).

  Can have the following values:
  - `rich` generic embed rendered from embed attributes
  - `image` image embed
  - `video` video embed
  - `gifv` animated gif image embed rendered as a video embed
  - `article` article embed
  - `link` linkd gif image embed rendered as a video embed
  """
  @type type :: String.t()

  defstruct [
    :title,
    :type,
    :description,
    :url,
    :timestamp,
    :color,
    :footer,
    :image,
    :thumbnail,
    :video,
    :provider,
    :author,
    :fields
  ]

  @doc """
  Maps the incoming data into struct form.

  ## Example:

  You can pass in invalid or missing data, it will ignore what doesn't match.

      iex> Wumpex.Resource.Embed.to_struct(%{})
      %Wumpex.Resource.Embed{
        title: nil,
        type: nil,
        description: nil,
        url: nil,
        timestamp: nil,
        color: nil,
        footer: nil,
        image: nil,
        thumbnail: nil,
        video: nil,
        provider: nil,
        author: nil,
        fields: nil
      }

  If you pass in known properties, they'll be mapped.

      iex> Wumpex.Resource.Embed.to_struct(%{"title" => "embed title"})
      %Wumpex.Resource.Embed{
        title: "embed title",
        type: nil,
        description: nil,
        url: nil,
        timestamp: nil,
        color: nil,
        footer: nil,
        image: nil,
        thumbnail: nil,
        video: nil,
        provider: nil,
        author: nil,
        fields: nil
      }
  """
  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:timestamp, nil, &to_datetime/1)
      |> Map.update(:footer, nil, &Footer.to_struct/1)
      |> Map.update(:image, nil, &Image.to_struct/1)
      |> Map.update(:thumbnail, nil, &Thumbnail.to_struct/1)
      |> Map.update(:video, nil, &Video.to_struct/1)
      |> Map.update(:provider, nil, &Footer.to_struct/1)
      |> Map.update(:author, nil, &Author.to_struct/1)
      |> Map.update(:fields, nil, &to_structs(&1, Field))

    struct(__MODULE__, data)
  end
end
