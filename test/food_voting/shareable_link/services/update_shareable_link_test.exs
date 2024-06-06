defmodule FoodVoting.ShareableLink.Services.UpdateShareableLinkTest do
  use FoodVoting.DataCase, async: true

  alias FoodVoting.ShareableLink.Services
  alias FoodVoting.Schemas

  describe "execute/1" do
    setup do
      {:ok, shareable_link} = Services.CreateShareableLink.execute()

      params = %{
        selected_options: [
          %{
            name: "My Restaurant",
            food_items: "Taco",
            address: "3856 Sawayn Lock",
            latitude: "-34.3589",
            longitude: "140.2222"
          }
        ]
      }

      %{params: params, shareable_link: shareable_link}
    end

    test "should update a shareable link", %{params: params, shareable_link: shareable_link} do
      assert {:ok, %Schemas.ShareableLinks{}} =
               Services.UpdateShareableLink.execute(shareable_link, params)
    end
  end
end
