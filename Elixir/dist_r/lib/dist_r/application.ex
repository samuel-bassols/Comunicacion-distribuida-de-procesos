defmodule DistR.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  # starts the supervision tree and its children

  use Application

  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: BackgroundJob.ClusterSupervisor]]},
      # Start the Telemetry supervisor
      DistRWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DistR.PubSub},
      # Start Horde procesess
      DistR.HordeRegistry,
      DistR.HordeSupervisor,
      DistR.NodeObserver,
      #start the execution table
      {DistR.Execute.Queue, []},

      # Start the Endpoint
      DistRWeb.Endpoint

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DistR.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DistRWeb.Endpoint.config_change(changed, removed)
    :ok
  end
  # Specifies the topology for libcluster. This can be changed to Gossip
  # Strategy if this topolgy is preferable to the aplication
  defp topologies do
    [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"n1@192.168.1.34",
            :"n2@192.168.1.32",
            :"n2@192.168.1.34"
          ]
        ]
      ]
    ]
  end
end
