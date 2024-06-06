defmodule FoodVoting.ShareableLink.Services.CreateShareableLink do
  @moduledoc false

  alias FoodVoting.Repo
  alias FoodVoting.Schemas
  alias FoodVoting.Utils

  @spec execute() :: {:ok, Schemas.ShareableLinks.t()} | {:error, Ecto.Changeset.t()}
  def execute() do
    {:ok, hash} = Utils.generate_unique_hash()

    %{hash: hash}
    |> Schemas.ShareableLinks.changeset()
    |> Repo.insert()
  end
end
