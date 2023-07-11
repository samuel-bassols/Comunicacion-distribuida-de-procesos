defmodule DistR.Execute.Queue do
  @moduledoc """
  Execute queue behaviour.
  """

  alias DistR.Execute

  @adapter Application.compile_env(:dist_r, __MODULE__)[:adapter]

  @type token :: String.t()
  @type result :: {:ok, Execute.t()} | {:error, term}
  @type counter :: {:ok, integer} | {:error, term}
  @type list_cache :: {:ok, [any]} | {:error, term}
  @type status :: {:ok, Execute.state} | {:error, term}

  @callback start(keyword) :: GenServer.on_start()
  @callback fetch(token()) :: result
  @callback insert(Execute.t()) :: result
  @callback update(Execute.t()) :: result
  @callback remove(Execute.t()) :: result
  @callback get_counter() :: counter
  @callback restart_counter(node) :: counter
  @callback update_counter(integer) :: counter
  @callback get_cache() :: list_cache
  defdelegate start_link(opts), to: @adapter
  defdelegate fetch(token), to: @adapter
  defdelegate insert(execute), to: @adapter
  defdelegate update(execute), to: @adapter
  defdelegate remove(execute), to: @adapter
  defdelegate get_counter(), to: @adapter
  defdelegate update_counter(n), to: @adapter
  defdelegate restart_counter(node), to: @adapter
  defdelegate get_cache(), to: @adapter
  defdelegate get_status(token), to: @adapter
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
