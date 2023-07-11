defmodule DistR.Execute.Tracker.Worker.Process do
  #Gen server that implements the worker status and execution.
  # status is mantained by passing messages to itself.

  use GenServer
  require Logger
  require System
  alias DistR.{Execute, Execute.Queue}
  alias Phoenix.PubSub
  @topic_web "change_web"
  @n_nodes String.to_integer(System.get_env("MAXP") || "3")

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    execute = Keyword.fetch!(opts, :execute)

    GenServer.start_link(__MODULE__, execute, name: name)
  end

  @impl GenServer
  #Inititalization funcion of the worker
  def init(execute) do
    #send message to go to start state
    schedule(:start, 1)
    PubSub.subscribe(DistR.PubSub, to_string(node()))
    {:ok, execute}
  end

  @impl GenServer
  #Functions that hadles incomming messages with the
  # message info :start
  def handle_info(:start, execute) do
    {_, counter}=Queue.get_counter()
    if @n_nodes>counter do
      {:ok, _}=Queue.update_counter(1)
      {:ok, new_execute} =
      execute
      |> Execute.with_node()
      |> Execute.with_pending_state()
      |> Queue.update()
      broadcast(@topic_web,:ok)
      #send message to go to processing state
      schedule(:process,1)
      {:noreply, new_execute}

    else
      {:ok, new_execute}=
        execute
        |> Execute.with_node()
        |> Execute.with_sleep_state()
        |> Queue.update()
      broadcast(@topic_web,:ok)
      {:noreply, new_execute}
    end
  end



  # Functions that hadles incomming messages with the
  # message info :process
  # Calls the commando execute_command to start the R
  # instance and execute the Execution
  def handle_info(:process, %Execute{token: token} = execute) do

    {:ok, new_execute} =
      execute
      |> Execute.with_node()
      |> Execute.with_processing_state()
      |> Queue.update()
      broadcast(@topic_web,:ok)
    case System.cmd(File.cwd! <> "" <> "/execute_command", [token]) do
        {_,0}->
          #send message to pass to go to ready state
          schedule(:ready, 1)
          {:noreply, new_execute}
        {_,1}->
          #send message to pass to go to processing state
          schedule(:error, 1)
          {:noreply, new_execute}
    end



  end
  # Functions that hadles incomming messages with the
  # message info :ready
  # the process ends after this state
  def handle_info(:ready, execute) do
    {:ok, new_execute} =
      execute
      |> Execute.with_node()
      |> Execute.with_end_time()
      |> Execute.with_ready_state()
      |> Queue.update()
    {:ok, _}=Queue.update_counter(-1)
    broadcast(@topic_web,:ok)
    broadcast(to_string(node()),:wake_up)

    {:stop, :normal, new_execute}
  end


  # Functions that hadles incomming messages with the
  # message info :error
  # the process ends after this state
  def handle_info(:error, execute) do
    {:ok, new_execute} =
      execute
      |> Execute.with_node()
      |> Execute.with_end_time()
      |> Execute.with_error_state()
      |> Queue.update()
    {:ok, _}=Queue.update_counter(-1)
    broadcast(to_string(node()),:wake_up)
    broadcast(@topic_web,:ok)



    {:stop, :normal, new_execute}
  end
  # Functions that hadles incomming messages with the
  # message info :wake_up
  # this message can only be seent by other
  # workers in the node when these finish
  def handle_info(:wake_up, execute) do

    if Execute.sleep?(execute) do
      {:ok, new_execute} =
      execute
      |> Execute.with_processing_state()
      |> Queue.update()
      schedule(:start,1)
      {:noreply, new_execute}
    else
      {:noreply, execute}
    end
  end

  #calls send_after withthe specified timeout
  defp schedule(action, timeout) do
    Process.send_after(self(), action, timeout)
  end
  #broadcasts the message to the specified topic
  defp broadcast(topic,msg) do
    PubSub.broadcast(DistR.PubSub, topic, msg)
  end
  # uncomment if you want to log events in the terminal
  #defp log(text) do
  #  Logger.info("----[#{node()}-#{inspect(self())}] #{__MODULE__} #{text}")
  #end
end
