defmodule DistRWeb.Router do
  use DistRWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DistRWeb.LayoutView, :root}
    #plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DistRWeb.AuthPlug
    plug Plug.Parsers, parsers: [:urlencoded]
  end

  #pipeline :csrf do
    #plug :protect_from_forgery # to here
  #end

  #set path to module that handles the path
  scope "/", DistRWeb do
    pipe_through :browser
    post "/execute", WebHookController, :execute
    post "/ready", WebHookController, :ready
    post "/delete", WebHookController, :delete
    live "/", PageLive, :index
  end
  #also set path to dashboard if environment is in development
  if Mix.env() == :dev do
    import Phoenix.LiveDashboard.Router
    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard",metrics: DistRWeb.Telemetry
    end
  end
end
