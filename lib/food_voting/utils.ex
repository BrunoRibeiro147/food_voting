defmodule FoodVoting.Utils do
  @moduledoc false

  def generate_unique_hash do
    {:ok, sqids} = Sqids.new()
    numbers = [Enum.random(1..1000), Enum.random(1..1000), Enum.random(1..1000)]
    {:ok, Sqids.encode!(sqids, numbers)}
  end
end
