defmodule SokobanTask1.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SokobanTask1Web.Telemetry,
      {DNSCluster, query: Application.get_env(:sokoban_task1, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SokobanTask1.PubSub},
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
