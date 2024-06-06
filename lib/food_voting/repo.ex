defmodule FoodVoting.Repo do
  use Ecto.Repo,
    otp_app: :food_voting,
    adapter: Ecto.Adapters.Postgres
end
