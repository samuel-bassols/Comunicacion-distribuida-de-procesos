defmodule DistR.Execute.Tracker do
  #tracker module that launches workers which executes functions. Also adds these workers to
  #HordeRegistry and HordeSupervisor

  alias __MODULE__.Worker
  alias DistR.{Execute, Execute.Queue, HordeRegistry, HordeSupervisor}

  @spec start(String.t(),String.t()) :: {:ok, Execute.t()} | {:error, term}
  def start(token,user) do
    with execute <- Execute.new(token: token,user: user),
         {:ok, execute} <- Queue.insert(execute),
         child_spec <- worker_spec(execute),
         {:ok, _} <- HordeSupervisor.start_child(child_spec) do
      {:ok, execute}
    end
  end

  defp worker_spec(%Execute{token: token} = execute) do
    %{
      id: {Worker, token},
      start: {Worker, :start_link, [[execute: execute, name: via_tuple(token)]]},
      type: :worker,
      restart: :transient
    }
  end

  defp via_tuple(token) do
    {:via, Horde.Registry, {HordeRegistry, {Execute, token}}}
  end
end
