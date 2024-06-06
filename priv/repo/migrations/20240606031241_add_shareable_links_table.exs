defmodule FoodVoting.Repo.Migrations.AddShareableLinksTable do
  use Ecto.Migration

  def change do
    create table(:shareable_links) do
      add :hash, :string
      add :selected_options, :jsonb, default: "[]"

      timestamps()
    end

    create index(:shareable_links, [:hash], unique: true)
  end
end
