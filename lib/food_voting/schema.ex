defmodule FoodVoting.Schema do
  @moduledoc """
  Macro for defining our Domain schemas/entities
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      alias Ecto.Changeset
      import Ecto.Changeset

      @type t :: %__MODULE__{}

      @primary_key {:id, :id, autogenerate: true}
      @timestamps_opts [type: :utc_datetime_usec]
      @foreign_key_type :string
    end
  end
end
