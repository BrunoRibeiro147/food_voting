defmodule FoodVoting.Schemas.ShareableLinks do
  @moduledoc false
  use FoodVoting.Schema

  @required_fields ~w(hash)a
  @optional_fields ~w(selected_food_trucks selected_options voting_status most_voted_food_truck)a

  schema "voting_room" do
    field :hash, :string
    field :selected_food_trucks, :string
    field :selected_options, {:array, :map}, virtual: true
    field :voting_status, Ecto.Enum, values: [:closed, :open, :finished]
    field :most_voted_food_truck, :string

    timestamps()
  end

  @spec changeset(schema :: __MODULE__.t(), params :: map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> encode_params()
  end

  defp encode_params(changeset) do
    case get_change(changeset, :selected_options) do
      nil ->
        changeset

      selected_options ->
        put_change(changeset, :selected_food_trucks, Jason.encode!(selected_options))
    end
  end
end
