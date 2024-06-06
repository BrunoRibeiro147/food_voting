defmodule FoodVoting.AI.OpenAI do
  use Tesla
  require Logger

  plug Tesla.Middleware.BaseUrl, "https://api.openai.com/v1"

  plug Tesla.Middleware.BearerAuth,
    token: Application.fetch_env!(:food_voting, __MODULE__)[:api_key]

  plug Tesla.Middleware.Headers, [{"OpenAI-Beta", "assistants=v2"}]
  plug Tesla.Middleware.JSON

  @thread_id Application.fetch_env!(:food_voting, __MODULE__)[:thread_id]
  @assistant_id Application.fetch_env!(:food_voting, __MODULE__)[:assistant_id]

  def send_message(_thread_id, message) do
    body = %{role: "user", content: message}

    case post("/threads/" <> @thread_id <> "/messages", body) do
      {:ok, %Tesla.Env{status: 200}} ->
        :ok

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when sending the user message"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when sending the user message"}
    end
  end

  def create_run() do
    body = %{assistant_id: @assistant_id}

    case post("/threads/" <> @thread_id <> "/runs", body) do
      {:ok, %Tesla.Env{status: 200, body: response}} ->
        {:ok, response["id"]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when sending the user message"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when sending the user message"}
    end
  end

  def retrieve_run(run_id) do
    case get("/threads/" <> @thread_id <> "/runs/" <> run_id) do
      {:ok, %Tesla.Env{status: 200, body: response}} ->
        {:ok, response}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when sending the user message"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when sending the user message"}
    end
  end

  @impl true
  def get_assistant_response(_user_thread_id) do
    case get("/threads/" <> @thread_id <> "/messages") do
      {:ok, %Tesla.Env{status: 200, body: response}} ->
        {:ok, build_assistant_response_data(response)}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when getting assistant message"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when getting assistant message"}
    end
  end

  def create_thread_to_user() do
    case post("/threads", %{}) do
      {:ok, %Tesla.Env{status: 200, body: response}} ->
        {:ok, response["id"]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when creating a user thread"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when creating a user thread"}
    end
  end

  def submit_functions_output(run_id, thread_id, output) do
    body = %{tool_outputs: output}

    case submit_functions_output_request(run_id, thread_id, body) do
      {:ok, %Tesla.Env{status: 200, body: response}} ->
        {:ok, response["id"]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error(%{status: status, body: body})
        {:error, "Error when creating a user thread"}

      {:error, error} ->
        Logger.error(%{error: error})
        {:error, "Error when creating a user thread"}
    end
  end

  defp submit_functions_output_request(run_id, _thread_id, body) do
    post(
      "/threads/" <>
        @thread_id <> "/runs/" <> run_id <> "/submit_tool_outputs",
      body
    )
  end

  defp build_assistant_response_data(%{"data" => [data | _tail]}) do
    assistant_message =
      data
      |> Map.get("content")
      |> List.first()
      |> Map.get("text")
      |> Map.get("value")

    {:ok, assistant_message}
  end

  defp parse_json_response(response) do
    response
    |> Jason.encode!()
    |> Jason.decode!(keys: :atoms!)
  end
end
