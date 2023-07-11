defmodule DistR.NodeObserver do
  use GenServer
  #GenServer which listens to events in the structure the node pool
  alias DistR.{HordeRegistry, HordeSupervisor,Execute.Queue}

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, nil}
  end
  #node up event
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(HordeRegistry)
    set_members(HordeSupervisor)

    {:noreply, state}
  end
  #node down event
  def handle_info({:nodedown, node, _node_type}, state) do
    set_members(HordeRegistry)
    set_members(HordeSupervisor)
    #restart counter to 0
    Queue.restart_counter(node)
    {:noreply, state}
  end

  defp set_members(name) do
    members = Enum.map([Node.self() | Node.list()], &{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
  end
end
