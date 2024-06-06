defmodule FoodVoting.Schemas.ShareableLinksTest do
  use FoodVoting.DataCase

  alias FoodVoting.Schemas

  describe "changeset/2" do
    setup do
      params = %{
        hash: "abcdefg",
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

      %{params: params}
    end

    test "returns a valid changeset if all params are valid", %{params: params} do
      assert %Ecto.Changeset{valid?: true} = Schemas.ShareableLinks.changeset(params)
    end

    test "returns an invalid changeset if name is missing" do
      assert %Ecto.Changeset{valid?: false} = Schemas.ShareableLinks.changeset(%{})
    end
  end
end
