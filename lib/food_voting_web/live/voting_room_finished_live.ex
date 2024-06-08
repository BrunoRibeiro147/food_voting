defmodule FoodVotingWeb.VotingRoomFinishedLive do
  use FoodVotingWeb, :live_view

  alias FoodVoting.ShareableLink.Services

  def mount(params, session, socket) do
    case Services.GetShareableLink.execute(params["hash"]) do
      {:ok, %{voting_status: :open} = voting_room} ->
        {:ok, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}/open_voting")}

      {:ok, %{voting_status: :closed}} ->
        {:ok, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}")}

      {:ok, %{voting_status: :finished} = voting_room} ->
        {:ok, assign(socket, voting_room_data: Jason.decode!(voting_room.most_voted_food_truck))}

      {:error, :shareable_link_not_found} ->
        {:ok, push_redirect(socket, to: ~p"/404")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center" style="height: 100svh">
      <a href="#">
        <h5 class="mb-8 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          The chosen food truck was:
        </h5>
      </a>

      <div class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
        <a href="#">
          <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            <%= @voting_room_data["name"] %>
          </h5>
        </a>
        <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
          Address: <%= @voting_room_data["address"] %>
        </p>

        <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
          Food Items: <%= @voting_room_data["food_items"] %>
        </p>

        <a
          href={"https://maps.google.com/?ll=#{@voting_room_data["latitude"]},#{@voting_room_data["longitude"]}"}
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          See on google maps
          <svg
            class="rtl:rotate-180 w-3.5 h-3.5 ms-2"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 14 10"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M1 5h12m0 0L9 1m4 4L9 9"
            />
          </svg>
        </a>
      </div>
    </div>
    """
  end
end
