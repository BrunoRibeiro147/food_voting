defmodule FoodVoting.Schemas.ShareableLinks do
  @moduledoc false
  use Core.Schema

  @required_fields ~w(hash )a
  @optional_fields ~w(selected_options)a

  schema "shareable_links" do
    field :hash, :string
    field :selected_options, :string

    timestamps()
  end

  @spec changeset(schema :: __MODULE__.t(), params :: map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
