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

  def send_message(message) do
    template_message = """
    Based on the template, I'm going to pass to you, I want you to return a minimum of 3 restaurants and the maximum of 7 restaurant options,
    the return is going to be a JSON in this format:
    {
      name: "Name of the restaurant",
      food_items: "Foods that this restaurant serves",
      address: "The address of the restaurant",
      latitude: "The restaurant latitude location",
      longitude: "The restaurant longitude location"
    }

    if the user asks something not related to food, or if the questions does not make sense return an error JSON:
    {error: "Could not understand the question"}:

    '''
    {message}
    '''
    """

    body = %{role: "user", content: String.replace(template_message, "{message}", message)}

    IO.inspect(body)

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
    body = %{assistant_id: @assistant_id, response_format: %{type: "json_object"}}

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

  def get_assistant_response() do
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

  defp build_assistant_response_data(%{"data" => [data | _tail]}) do
    assistant_message =
      data
      |> Map.get("content")
      |> List.first()
      |> Map.get("text")
      |> Map.get("value")

    {:ok, assistant_message}
  end
end
