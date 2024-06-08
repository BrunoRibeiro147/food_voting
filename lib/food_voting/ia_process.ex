defmodule FoodVoting.IAProcess do
  use GenServer

  alias FoodVoting.AI.OpenAI

  @impl true
  def init(state) do
    state =
      state
      |> Map.put_new(:interval, 2_000)
      |> Map.put_new(:schedule, nil)

    {:ok, state, 10_000}
  end

  @impl true
  def handle_cast({:send, message}, state) do
    OpenAI.send_message(message)
    {:ok, run_id} = OpenAI.create_run()

    {:noreply, Map.put(state, :schedule, schedule_work(state.interval, run_id))}
  end

  @impl true
  def handle_info({:pooling, run_id}, state) do
    {:ok, response} = OpenAI.retrieve_run(run_id)

    case response["status"] do
      "completed" ->
        send(self(), :pooling_done)
        {:noreply, state}

      _value ->
        {:noreply, Map.put(state, :schedule, schedule_work(state.interval, run_id))}
    end
  end

  @impl true
  def handle_info(:pooling_done, state) do
    {:ok, assistant_response} = OpenAI.get_assistant_response()

    Phoenix.PubSub.broadcast(
      FoodVoting.PubSub,
      state.topic,
      {:food_trucks_options, assistant_response}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, "finished", state}
  end

  defp schedule_work(interval, run_id) when is_integer(interval) and interval > 0,
    do: Process.send_after(self(), {:pooling, run_id}, interval)
end
