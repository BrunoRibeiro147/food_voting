defmodule FoodVoting.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FoodVotingWeb.Telemetry,
      FoodVoting.Repo,
      {DNSCluster, query: Application.get_env(:food_voting, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FoodVoting.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: FoodVoting.Finch},
      # Start a worker by calling: FoodVoting.Worker.start_link(arg)
      # {FoodVoting.Worker, arg},
      # Start to serve requests, typically the last entry
      FoodVotingWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FoodVoting.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FoodVotingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
