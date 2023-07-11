defmodule DistRWeb.AuthPlug do
  @moduledoc """
  Fake authentication plug
  """
  @behaviour Plug

  alias DistR.Id
  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Conn.get_session(conn) do
      %{"user_id" => _} ->
        conn

      _ ->
        Conn.put_session(conn, :user_id, Id.generate())
    end
  end
end
