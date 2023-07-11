defmodule DistR.Execute.Tracker.Worker do
  #Defines the worker behaviour and delegates it to the process module

  @adapter Application.compile_env(:dist_r, __MODULE__)[:adapter]

  @callback start_link(keyword) :: GenServer.on_start()

  defdelegate start_link(opts), to: @adapter
end
