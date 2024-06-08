defmodule FoodVotingWeb.VotingRoomLive do
  use FoodVotingWeb, :live_view

  alias FoodVoting.ShareableLink.Services
  alias FoodVoting.Utils
  alias FoodVotingWeb.Presence

  def mount(params, _session, socket) do
    topic = params["hash"]

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FoodVoting.PubSub, topic)

      username = Utils.generate_silly_name()

      {:ok, _} =
        Presence.track(self(), topic, username, %{
          username: username
        })
    end

    case Services.GetShareableLink.execute(params["hash"]) do
      {:ok, %{voting_status: :open}} ->
        {:ok, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}/open_voting")}

      {:ok, %{voting_status: :finished}} ->
        {:ok, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}/finished")}

      {:ok, voting_room} ->
        {:ok, default_assigns(socket, params, voting_room)}

      {:error, :shareable_link_not_found} ->
        {:ok, push_redirect(socket, to: ~p"/404")}
    end
  end

  defp default_assigns(socket, params, voting_room) do
    presences = Presence.list(params["hash"])

    socket
    |> assign(room_hash: params["hash"])
    |> assign(form: to_form(%{"message" => ""}))
    |> assign(:presences, Presence.simple_presence_map(presences))
    |> assign(loading_response: false)
    |> assign(food_trucks_options: [])
    |> assign(voting_room: voting_room)
    |> assign(:selected_food_trucks, build_selected_food_trucks(voting_room.selected_food_trucks))
    |> assign(:ai_process_pid, nil)
  end

  defp build_selected_food_trucks(nil), do: []

  defp build_selected_food_trucks(selected_food_trucks), do: Jason.decode!(selected_food_trucks)

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    presences = Presence.handle_presence_diff(socket.assigns.presences, diff)

    {:noreply, assign(socket, presences: presences)}
  end

  def handle_event("ask_ai", %{"message" => message}, socket) do
    {:ok, pid} = GenServer.start_link(FoodVoting.IAProcess, %{topic: socket.assigns.room_hash})
    GenServer.cast(pid, {:send, message})

    {:noreply, assign(socket, food_trucks_options: [], loading_response: true)}
  end

  def handle_event("select_food_truck_option", params, socket) do
    selected_food_trucks = socket.assigns.selected_food_trucks

    with true <- length(selected_food_trucks) < 5,
         nil <- Enum.find(selected_food_trucks, fn option -> option["name"] == params["name"] end) do
      new_selected_food_trucks = [params | selected_food_trucks]

      {:ok, updated_voting_room} =
        Services.UpdateShareableLink.execute(
          socket.assigns.voting_room,
          %{selected_options: new_selected_food_trucks}
        )

      Phoenix.PubSub.broadcast(
        FoodVoting.PubSub,
        socket.assigns.room_hash,
        {:food_truck_option_updated,
         %{new_options: new_selected_food_trucks, voting_room: updated_voting_room}}
      )

      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("remove_food_truck_option", params, socket) do
    selected_food_trucks = socket.assigns.selected_food_trucks

    new_selected_food_trucks =
      Enum.filter(selected_food_trucks, fn option -> option["name"] != params["name"] end)

    {:ok, updated_voting_room} =
      Services.UpdateShareableLink.execute(
        socket.assigns.voting_room,
        %{selected_options: new_selected_food_trucks}
      )

    Phoenix.PubSub.broadcast(
      FoodVoting.PubSub,
      socket.assigns.room_hash,
      {:food_truck_option_updated,
       %{new_options: new_selected_food_trucks, voting_room: updated_voting_room}}
    )

    {:noreply, socket}
  end

  def handle_event("open_voting", _params, socket) do
    Services.UpdateShareableLink.execute(socket.assigns.voting_room, %{
      selected_food_trucks: socket.assigns.voting_room.selected_food_trucks,
      voting_status: :open
    })

    Phoenix.PubSub.broadcast(
      FoodVoting.PubSub,
      socket.assigns.room_hash,
      {:open_voting, ""}
    )

    {:noreply, push_redirect(socket, to: ~p"/rooms/#{socket.assigns.room_hash}/open_voting")}
  end

  def handle_info({:food_trucks_options, response}, socket) do
    {:noreply, assign(socket, food_trucks_options: response, loading_response: false)}
  end

  def handle_info({:open_voting, _msg}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/rooms/#{socket.assigns.room_hash}/open_voting")}
  end

  def handle_info({:food_truck_option_updated, info}, socket) do
    %{new_options: new_selected_food_trucks, voting_room: updated_voting_room} = info

    {:noreply,
     assign(socket,
       selected_food_trucks: new_selected_food_trucks,
       voting_room: updated_voting_room
     )}
  end

  defp show_description_message(food_truck_options, true), do: false

  defp show_description_message(food_truck_options, false), do: Enum.empty?(food_truck_options)

  def render(assigns) do
    ~H"""
    <div class="py-8 px-4 mx-auto max-w-screen-xl text-center lg:py-16 lg:px-12">
      <div class="grid grid-cols-4 grid-gap-4">
        <div class="flex col-span-1">
          <div class="flex flex-col">
            <span class="text-md font-medium mb-4">Participants</span>
            <div :for={{_key, meta} <- @presences} class="mb-4 text-lg space-x-2">
              <span><%= meta.username %></span>
            </div>
          </div>
          <div class="ml-8 border border-gray-2" />
        </div>

        <div class="flex col-span-2 align-center justify-center">
          <div class="flex flex-col w-5/6">
            <span class="text-md font-medium mb-8">Ask a question</span>
            <span
              :if={show_description_message(@food_trucks_options, @loading_response)}
              class="text-md font-medium text-gray-500"
            >
              We user AI to return the bests food truck options based on your question
            </span>

            <.spinner loading={@loading_response} />

            <div
              :for={option <- @food_trucks_options}
              :if={!Enum.empty?(@food_trucks_options)}
              class="flex py-2 border rounded items-center mb-2 hover:bg-blue-500 hover:cursor-pointer group"
              phx-click={JS.push("select_food_truck_option", value: option)}
            >
              <span class="ms-2 text-lg font-medium text-gray-900 group-hover:text-white dark:text-gray-300">
                <%= option["name"] %>
              </span>
            </div>

            <.form for={@form} phx-submit="ask_ai">
              <div class="flex justify-between mt-8">
                <input
                  name="message"
                  class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  placeholder="Give me food trucks that sells tacos"
                />

                <button
                  type="submit"
                  class="ml-4 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-full text-sm p-2.5 text-center inline-flex items-center me-2 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
                >
                  <svg
                    class="w-6 h-6 text-white"
                    aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke="currentColor"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6v13m0-13 4 4m-4-4-4 4"
                    />
                  </svg>
                  <span class="sr-only">send message to ai</span>
                </button>
              </div>
            </.form>
          </div>
        </div>

        <div class="flex col-span-1">
          <div class="mr-12 border border-gray-2" />
          <div class="flex flex-col items-center">
            <span class="text-md font-medium mb-4">Selected Food Trucks</span>

            <div :for={selected <- @selected_food_trucks} class="flex items-center mb-4">
              <span class="text-md font-medium text-gray-600"><%= selected["name"] %></span>
              <button
                phx-click={JS.push("remove_food_truck_option", value: selected)}
                type="button"
                class="ml-4 border border-red-700 hover:bg-red-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-full text-sm inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
              >
                <svg
                  class="w-5 h-5 text-gray-800 dark:text-white"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 12h14"
                  />
                </svg>
                <span class="sr-only">Remove selected options</span>
              </button>
            </div>

            <button
              type="button"
              phx-click="open_voting"
              class="mt-6 px-6 py-3.5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
            >
              Start voting
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :loading, :boolean

  defp spinner(assigns) do
    ~H"""
    <div :if={@loading} class="flex justify-center" role="status">
      <svg
        aria-hidden="true"
        class="w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600"
        viewBox="0 0 100 101"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
          fill="currentColor"
        />
        <path
          d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
          fill="currentFill"
        />
      </svg>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end
end
