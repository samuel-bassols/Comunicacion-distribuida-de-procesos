defmodule DistRWeb.PageLive do
  use DistRWeb, :live_view

  alias Phoenix.PubSub
  @topic_web "change_web"
  #mounts the table of execution to the view
  @impl Phoenix.LiveView
  def mount(_params, _, socket) do
    PubSub.subscribe(DistR.PubSub, @topic_web)
    {_,table}=DistR.get_table()
    {:ok, assign(socket, :table, table)}
  end


  # handles any broadcast on the topic that changes to the table are
  # notified on
  @impl Phoenix.LiveView
  def handle_info(_, socket) do
    {_,table}=DistR.get_table()
    {:noreply, assign(socket, :table, table)}
  end
end
