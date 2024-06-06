defmodule FoodVoting.ShareableLink.Services.GetShareableLink do
  @moduledoc false

  alias FoodVoting.Repo
  alias FoodVoting.Schemas

  @spec execute(link_hash :: String.t()) ::
          {:ok, Schemas.ShareableLinks.t()} | {:error, Ecto.Changeset.t()}
  def execute(link_hash) do
    case Repo.get_by(Schemas.ShareableLinks, hash: link_hash) do
      nil -> {:error, :shareable_link_not_found}
      shareable_link -> {:ok, shareable_link}
    end
  end
end
