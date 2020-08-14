defmodule Wumpex.Resource.Embed do
  import Wumpex.Resource

  alias Wumpex.Resource
  alias Wumpex.Resource.EmbedFooter
  alias Wumpex.Resource.EmbedImage
  alias Wumpex.Resource.EmbedThumbnail
  alias Wumpex.Resource.EmbedVideo
  alias Wumpex.Resource.EmbedProvider
  alias Wumpex.Resource.EmbedAuthor
  alias Wumpex.Resource.EmbedField

  @type t :: %__MODULE__{
          title: String.t(),
          type: String.t(),
          description: String.t(),
          url: String.t(),
          timestamp: DateTime.t(),
          color: non_neg_integer(),
          footer: EmbedFooter.t(),
          image: EmbedImage.t(),
          thumbnail: EmbedThumbnail.t(),
          video: EmbedVideo.t(),
          provider: EmbedProvider.t(),
          author: EmbedAuthor.t(),
          fields: [EmbedField.t()]
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

  @spec to_struct(data :: map()) :: t()
  def to_struct(data) when is_map(data) do
    data =
      data
      |> to_atomized_map()
      |> Map.update(:timestamp, nil, &to_datetime/1)
      |> Map.update(:footer, nil, &EmbedFooter.to_struct/1)
      |> Map.update(:image, nil, &EmbedImage.to_struct/1)
      |> Map.update(:thumbnail, nil, &EmbedThumbnail.to_struct/1)
      |> Map.update(:video, nil, &EmbedVideo.to_struct/1)
      |> Map.update(:provider, nil, &EmbedFooter.to_struct/1)
      |> Map.update(:author, nil, &EmbedAuthor.to_struct/1)
      |> Map.update(:fields, nil, fn fields -> to_structs(fields, EmbedField) end)

    struct!(__MODULE__, data)
  end
end
