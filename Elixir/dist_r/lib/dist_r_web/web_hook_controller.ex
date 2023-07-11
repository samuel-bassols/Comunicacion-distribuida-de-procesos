defmodule DistRWeb.WebHookController do
  # controller for incoming petitions to the system
  import Plug.Conn
  use Phoenix.Controller
  #Incomming execute
  def execute(conn, _opts) do

    {:ok, body, conn} = read_body(conn, length: 10_000)
    {code,msg}=case DistR.is_ready(body) do
      {:error, _}->
        DistR.start_execute(body,conn.params["user"])
        {200,"starting"}
      {:ok, _}->
        {200,"already started"}
    end
    IO.puts(:stderr, "Incoming Execution")
    IO.puts(:stderr, conn.params["user"])
    send_resp(conn,code, msg)
  end
  #Incomming status check
  def ready(conn, _opts) do

    {:ok, body, conn} = read_body(conn, length: 10_000)
    IO.puts(:stderr, "Incoming status petition")
    {code,msg}=case DistR.is_ready(body) do
      {:error, _}->
        {200,"not_found"}
      {:ok, :ready}->
        {200,"ready"}
      {:ok, :error}->
        {200,"error"}
      {:ok, _}->
        {200,"executing"}
    end
    IO.puts(:stderr, msg)
    conn=put_resp_content_type(conn,"text/plain")
    send_resp(conn,code, msg)

  end
end
