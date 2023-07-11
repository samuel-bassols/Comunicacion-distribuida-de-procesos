# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :dist_r, DistRWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "mvU3QOuKWNh9w8CStVFsE9QSakUcgsvFDeZ5Ux76c09izdDXH7A+Xp4A0Wf32jlF",
  render_errors: [view: DistRWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DistR.PubSub,
  live_view: [signing_salt: "bwIZx1xY"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Execute repo configuration
config :dist_r, DistR.Execute.Queue,
  adapter: DistR.Execute.Queue.Nebulex

# Execute tracker worker configuration
config :dist_r, DistR.Execute.Tracker.Worker,
  adapter: DistR.Execute.Tracker.Worker.Process

config :dist_r, DistR.Execute.Queue,
  gc_interval: :timer.hours(12),
  max_size: 1_00_000,
  allocated_memory: 2_000_000_000,
  gc_cleanup_min_timeout: :timer.seconds(10),
  gc_cleanup_max_timeout: :timer.minutes(10)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
