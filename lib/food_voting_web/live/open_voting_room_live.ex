defmodule FoodVotingWeb.OpenVotingRoomLive do
  use FoodVotingWeb, :live_view

  alias FoodVoting.ShareableLink.Services
  alias FoodVoting.Utils
  alias FoodVotingWeb.Presence

  def mount(params, _params, socket) do
    topic = params["hash"]
    username = Utils.generate_silly_name()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FoodVoting.PubSub, topic)

      {:ok, _} =
        Presence.track(self(), topic, username, %{
          username: username,
          voted: false
        })
    end

    case Services.GetShareableLink.execute(params["hash"]) do
      {:ok, %{voting_status: :open} = voting_room} ->
        {:ok, default_assigns(socket, params, voting_room, username)}

      {:ok, %{voting_status: :closed}} ->
        {:ok, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}")}

      {:error, :shareable_link_not_found} ->
        {:ok, push_redirect(socket, to: ~p"/404")}
    end
  end

  defp default_assigns(socket, params, voting_room, username) do
    presences = Presence.list(params["hash"])

    voting_options =
      voting_room.selected_food_trucks
      |> Jason.decode!(keys: :atoms)
      |> Enum.map(&Map.put(&1, :selected, false))

    assign(socket,
      presences: Presence.simple_presence_map(presences),
      voting_options: voting_options,
      voting_room: voting_room,
      username: username,
      voted: false
    )
  end

  def handle_event("select_option", %{"name" => name}, socket) do
    voting_options = socket.assigns.voting_options

    voting_options =
      Enum.map(voting_options, fn option ->
        case option.name == name do
          true -> Map.put(option, :selected, true)
          false -> Map.put(option, :selected, false)
        end
      end)

    {:noreply, assign(socket, voting_options: voting_options)}
  end

  def handle_event("add_vote", _, socket) do
    room_hash = socket.assigns.voting_room.hash
    username = socket.assigns.username

    voted_option =
      Enum.find(socket.assigns.voting_options, fn option -> option.selected == true end)

    Services.VoteShareableLink.execute(room_hash, voted_option.name)

    socket = update(socket, :voted, fn _ -> true end)

    %{metas: [meta | _]} = Presence.get_by_key(room_hash, username)

    new_map = %{meta | voted: socket.assigns.voted}

    Presence.update(self(), room_hash, username, new_map)

    {:noreply, put_flash(socket, :info, "Your vote was computed")}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    presences = Presence.handle_presence_diff(socket.assigns.presences, diff)

    case Enum.all?(presences, fn {_key, value} -> value.voted == true end) do
      true ->
        room_hash = socket.assigns.voting_room.hash
        Services.CalculateVotes.execute(room_hash)
        {:noreply, push_redirect(socket, to: ~p"/rooms/#{room_hash}/finished")}

      false ->
        {:noreply, assign(socket, presences: presences)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center space-x-6" style="height: 100svh">
      <.participant_list presences={@presences} />
      <.voting_options_list voting_options={@voting_options} />
    </div>
    """
  end

  attr :presences, :map

  defp participant_list(assigns) do
    ~H"""
    <div class="w-full max-w-md p-4 bg-white border border-gray-200 rounded-lg shadow sm:p-8 dark:bg-gray-800 dark:border-gray-700">
      <div class="flex items-center justify-between mb-4">
        <h5 class="text-xl font-bold leading-none text-gray-900 dark:text-white">
          Participants
        </h5>
      </div>
      <div class="flow-root">
        <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
          <li :for={{_key, meta} <- @presences} class="py-3 sm:py-4">
            <div class="flex items-center">
              <div class="flex-1 min-w-0 ms-4">
                <p class="text-sm font-medium text-gray-900 truncate dark:text-white">
                  <%= meta.username %>
                </p>
              </div>

              <svg
                :if={meta.voted}
                class="w-6 h-6 text-green-500 dark:text-white"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  fill-rule="evenodd"
                  d="M2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10S2 17.523 2 12Zm13.707-1.293a1 1 0 0 0-1.414-1.414L11 12.586l-1.793-1.793a1 1 0 0 0-1.414 1.414l2.5 2.5a1 1 0 0 0 1.414 0l4-4Z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  attr :voting_options, :list

  defp voting_options_list(assigns) do
    ~H"""
    <div class="w-full max-w-md p-4 bg-white border border-gray-200 rounded-lg shadow sm:p-8 dark:bg-gray-800 dark:border-gray-700">
      <div class="flex items-center justify-between mb-4">
        <h5 class="text-xl font-bold leading-none text-gray-900 dark:text-white">
          Options
        </h5>
      </div>
      <div class="flow-root">
        <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
          <li :for={option <- @voting_options} class="py-3 sm:py-4">
            <div
              class={"flex items-center py-2 rounded hover:cursor-pointer #{if option.selected, do: "bg-green-200"}"}
              phx-click="select_option"
              phx-value-name={option.name}
            >
              <div class="flex-1 min-w-0 ms-4">
                <p class="text-sm font-medium text-gray-900 truncate dark:text-white">
                  <%= option.name %>
                </p>
              </div>
            </div>
          </li>
        </ul>

        <button
          class="inline-flex items-center justify-center w-full mt-4 px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
          phx-click="add_vote"
        >
          Vote
        </button>
      </div>
    </div>
    """
  end
end
