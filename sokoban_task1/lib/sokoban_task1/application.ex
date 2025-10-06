defmodule SokobanTask1.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Load environment variables
    SokobanTask1.Env.load_env()

    children = [
      # Start the Ecto repository
      SokobanTask1.Repo,
      # Start Redis connection (commented out for now)
      # {Redix, SokobanTask1.Env.redis_config()},
      # Start Telemetry
      SokobanTask1Web.Telemetry,
      # Start DNS Cluster
      {DNSCluster, query: Application.get_env(:sokoban_task1, :dns_cluster_query) || :ignore},
      # Start PubSub
      {Phoenix.PubSub, name: SokobanTask1.PubSub},
      # Start the Endpoint (http/https)
      SokobanTask1Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SokobanTask1.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SokobanTask1Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
