defmodule FoodVoting.ShareableLink.Services.UpdateShareableLink do
  alias FoodVoting.Schemas

  alias FoodVoting.Repo
  alias FoodVoting.Schemas

  @spec execute(shareable_link :: Schemas.ShareableLinks, params :: map()) ::
          {:ok, Schemas.ShareableLinks.t()} | {:error, Ecto.Changeset.t()}
  def execute(shareable_link, params) do
    shareable_link
    |> Schemas.ShareableLinks.changeset(params)
    |> Repo.update()
  end
end
