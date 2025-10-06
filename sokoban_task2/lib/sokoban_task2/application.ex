defmodule SokobanTask2.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Repo
      SokobanTask2.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: SokobanTask2.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SokobanTask2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
