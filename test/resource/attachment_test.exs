defmodule Wumpex.Resource.AttachmentTest do
  @moduledoc false
  use ExUnit.Case

  alias Wumpex.Resource.Attachment

  describe "to_struct/1 should" do
    test "parse an example for an attachment" do
      example = %{
        "id" => 746_840_255_222_513_634,
        "filename" => "README.md",
        "proxy_url" => "proxied-url",
        "size" => 490,
        "url" => "url"
      }

      assert %Attachment{
               id: 746_840_255_222_513_634,
               filename: "README.md",
               proxy_url: "proxied-url",
               size: 490,
               url: "url"
             } = Attachment.to_struct(example)
    end
  end
end
