defmodule FoodVotingWeb.HomeLive do
  use FoodVotingWeb, :live_view

  alias FoodVoting.ShareableLink.Services.CreateShareableLink

  def mount(_params, _session, socket) do
    room_form = to_form(%{"hash" => ""})

    {:ok, assign(socket, room_form: room_form)}
  end

  def handle_event("create_room", _params, socket) do
    case CreateShareableLink.execute() do
      {:ok, shareable_link} ->
        {:noreply, push_navigate(socket, to: ~p"/rooms/#{shareable_link.hash}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong please try again")}
    end
  end

  def handle_event("enter_room", params, socket) do
    {:noreply, push_redirect(socket, to: ~p"/rooms/#{params["hash"]}")}
  end

  def render(assigns) do
    ~H"""
    <section class="bg-white dark:bg-gray-900">
      <div class="py-8 px-4 mx-auto max-w-screen-md text-center lg:py-16 lg:px-12">
        <h1 class="mb-4 text-4xl font-extrabold tracking-tight leading-none text-gray-900 md:text-5xl lg:text-6xl dark:text-white">
          Food AI
        </h1>
        <p class="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 xl:px-48 dark:text-gray-400">
          Create a easy voting room to you and your friends find the perfect place to go
        </p>
        <div class="flex flex-col mb-8 lg:mb-16 space-y-8">
          <button
            phx-click="create_room"
            type="button"
            class="px-6 py-3.5  text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
          >
            Create a new room
          </button>

          <p class="text-lg font-normal text-gray-500 lg:text-xl sm:px-16 xl:px-48 dark:text-gray-400">
            Or
          </p>

          <.simple_form for={@room_form} phx-submit="enter_room" class="space-y-8">
            <.input
              field={@room_form[:hash]}
              type="text"
              id="company"
              class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
              placeholder="Enter a room hash"
              required
            />

            <button
              type="submit"
              class="px-6 py-3.5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
            >
              Enter on a room
            </button>
          </.simple_form>
        </div>
      </div>
    </section>
    """
  end
end
