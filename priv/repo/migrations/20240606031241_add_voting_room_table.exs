defmodule FoodVoting.Repo.Migrations.AddVotingRoomTable do
  use Ecto.Migration

  def change do
    create table(:voting_room) do
      add :hash, :string
      add :selected_food_trucks, :text
      add :voting_status, :string, default: "closed"
      add :most_voted_food_truck, :text
      add :food_truck_voted, :string

      timestamps()
    end

    create index(:voting_room, [:hash], unique: true)
  end
end
