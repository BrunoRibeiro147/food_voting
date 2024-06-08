defmodule FoodVoting.ShareableLink.Services.VoteShareableLink do
  alias FoodVoting.ShareableLink.Services

  def execute(id, name) do
    with {:ok, shareable_link} <- Services.GetShareableLink.execute(id),
         {:ok, selected_options} <- find_voted_options(shareable_link, name) do
      Services.UpdateShareableLink.execute(shareable_link, %{selected_options: selected_options})
    end
  end

  defp find_voted_options(shareable_link, name) do
    selected_options = Jason.decode!(shareable_link.selected_food_trucks)

    selected_options
    |> Enum.find(fn options -> options["name"] == name end)
    |> case do
      nil -> {:error, :not_found}
      option -> update_vote_on_option(selected_options, option)
    end
  end

  defp update_vote_on_option(selected_options, voted_option) do
    voted_option =
      Map.update(voted_option, "vote_count", 1, fn count -> count + 1 end)

    selected_options =
      Enum.map(selected_options, fn option ->
        case option["name"] == voted_option["name"] do
          true -> voted_option
          false -> option
        end
      end)

    {:ok, selected_options}
  end
end
