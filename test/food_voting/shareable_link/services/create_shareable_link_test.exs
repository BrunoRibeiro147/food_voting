defmodule FoodVoting.ShareableLink.Services.CreateShareableLinkTest do
  use FoodVoting.DataCase, async: true

  alias FoodVoting.ShareableLink.Services
  alias FoodVoting.Schemas

  describe "execute/1" do
    test "should create a shareable link" do
      assert {:ok, %Schemas.ShareableLinks{}} = Services.CreateShareableLink.execute()
    end
  end
end
