defmodule FoodVotingWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :food_voting,
    pubsub_server: FoodVoting.PubSub

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {key, %{metas: [meta | _tail]}} ->
      {key, meta}
    end)
  end

  def handle_presence_diff(source, diff) do
    source
    |> remove_presences(diff.leaves)
    |> add_presences(diff.joins)
  end

  defp remove_presences(source, leaves) do
    Enum.reduce(leaves, source, fn {user_id, _}, acc ->
      Map.delete(acc, user_id)
    end)
  end

  defp add_presences(source, joins) do
    simple_presence_map = simple_presence_map(joins)
    Map.merge(source, simple_presence_map)
  end
end
