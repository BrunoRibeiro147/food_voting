defmodule FoodVoting.ShareableLink.Services.CalculateVotes do
  alias FoodVoting.ShareableLink.Services

  def execute(id) do
    with {:ok, %{voting_status: :open} = link} <- Services.GetShareableLink.execute(id),
         {:ok, most_voted} <- calculate_votes(link) do
      Services.UpdateShareableLink.execute(link, %{
        most_voted_food_truck: Jason.encode!(most_voted),
        voting_status: :finished
      })
    else
      _ -> {:error, :not_found}
    end
  end

  defp calculate_votes(link) do
    # Filter unvoted options
    selected_options =
      link.selected_food_trucks
      |> Jason.decode!()
      |> Enum.filter(fn option -> Map.get(option, "vote_count") != nil end)

    {:ok, do_calculate_votes(selected_options, %{"vote_count" => 0})}
  end

  defp do_calculate_votes([], most_voted), do: most_voted

  defp do_calculate_votes([head | tail], most_voted) do
    case head["vote_count"] >= most_voted["vote_count"] do
      true -> do_calculate_votes(tail, head)
      false -> do_calculate_votes(tail, most_voted)
    end
  end
end
