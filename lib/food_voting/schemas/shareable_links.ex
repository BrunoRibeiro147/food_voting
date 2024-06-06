defmodule FoodVoting.Schemas.ShareableLinks do
  @moduledoc false
  use FoodVoting.Schema

  @required_fields ~w(hash)a
  @optional_fields ~w(selected_food_trucks selected_options)a

  schema "shareable_links" do
    field :hash, :string
    field :selected_food_trucks, :string
    field :selected_options, {:array, :map}, virtual: true

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
    selected_options =
      changeset
      |> get_change(:selected_options)
      |> Jason.encode!()

    put_change(changeset, :selected_food_trucks, selected_options)
  end
end
