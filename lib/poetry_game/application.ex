defmodule PoetryGame.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      PoetryGame.Repo,
      # Start the Telemetry supervisor
      PoetryGameWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PoetryGame.PubSub},
      # Start the Endpoint (http/https)
      PoetryGameWeb.Endpoint,
      # Presence to track people joining/leaving games
      PoetryGameWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PoetryGame.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PoetryGameWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
