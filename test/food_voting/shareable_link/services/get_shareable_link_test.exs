defmodule FoodVoting.ShareableLink.Services.GetShareableLinkTest do
  use FoodVoting.DataCase, async: true

  alias FoodVoting.ShareableLink.Services
  alias FoodVoting.Schemas

  describe "execute/1" do
    setup do
      {:ok, shareable_link} = Services.CreateShareableLink.execute()

      %{shareable_link: shareable_link}
    end

    test "should return a shareable link if hash exists", %{
      shareable_link: shareable_link
    } do
      assert {:ok, %Schemas.ShareableLinks{}} =
               Services.GetShareableLink.execute(shareable_link.hash)
    end

    test "should return an error if hash does not exist" do
      assert {:error, :shareable_link_not_found} =
               Services.GetShareableLink.execute("abcdekf")
    end
  end
end
