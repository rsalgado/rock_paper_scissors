defmodule RockPaperScissors.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      RockPaperScissorsWeb.Endpoint,
      # Create a dynamic supervisor to control the individual game GenServers
      {DynamicSupervisor, strategy: :one_for_one, name: RockPaperScissors.GamesSupervisor},
      # Create a registry to allow to look up for game GenServers using its string name
      Registry.child_spec(keys: :unique, name: RockPaperScissors.GamesRegistry)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RockPaperScissors.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RockPaperScissorsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
