defmodule Fly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @daily :timer.hours(24)

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FlyWeb.Telemetry,
      # Start the Ecto repository
      Fly.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Fly.PubSub},
      # Start Finch
      {Finch, name: Fly.Finch},
      # Start the Endpoint (http/https)
      FlyWeb.Endpoint
      # Start a worker by calling: Fly.Worker.start_link(arg)
      # {Fly.Worker, arg}
    ]

    env = Application.get_env(:fly, :env)
    children = children ++ maybe_start_stripe_sync_service(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_start_stripe_sync_service(env) do
    if env == :test do
      []
    else
      [
        {Fly.Stripe.InvoiceScheduler, interval: @daily},
        {Fly.Stripe.SyncService, []}
      ]
    end
  end
end
