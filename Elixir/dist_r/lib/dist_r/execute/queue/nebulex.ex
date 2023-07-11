defmodule DistR.Execute.Queue.Nebulex do
  # Implements the behaviour DistR.Queue
  # Nebulex is used with the replicated adapter
  use Nebulex.Cache,
    otp_app: :dist_r,
    adapter: Nebulex.Adapters.Replicated

  alias DistR.{Execute, Execute.Queue}
  require Logger
  @behaviour Queue

  @impl Queue
  def start(opts) do
    start_link(opts)
  end

  @impl Queue
  def fetch(token) do
    case get(token) do
      nil ->
        {:error, :not_found}

      execute ->
        {:ok, execute}
    end
  end

  @impl Queue
  def insert(%Execute{token: token} = execute) do
    if put_new(token, execute) do
      {:ok, execute}
    else
      {:error, :unexpected_error}
    end
  end

  @impl Queue
  def update(%Execute{token: token} = execute) do
    :ok = put(token, execute)

    {:ok, execute}
  end

  @impl Queue
  def remove(%Execute{token: token} = execute) do
    :ok = delete(token)

    {:ok, execute}
  end

  @impl Queue
  def get_counter() do

    case incr(node(),0) do
      nil ->
        {:error, :not_found}

      counter ->
        {:ok, counter}
    end
  end

  @impl Queue
  def update_counter(n) do
    case incr(node(),n) do
      nil ->
        {:error, :not_found}

      counter ->
        {:ok, counter}
    end
  end

  @impl Queue
  def restart_counter(node) do
    :ok = put(node, 0)

    {:ok, 0}
  end

  @impl Queue
  def get_cache() do
    case all(nil, return:  {:key, :value}) do
      nil ->
        {:error, :not_found}


      []->{:ok,[]}

      val ->
        l1=Enum.filter(val,&match?({_,%Execute{}}, &1))
        l=Enum.map(l1,
          fn  {_,%Execute{}=execute}-> execute end)
        l=Enum.sort(l, fn x, y ->
          case Time.compare(x.start_time, y.start_time) do
            :lt -> true
            _ -> false
          end
        end)
        {:ok,l}

    end
  end

  def get_status(token) do
    case get(token) do
      nil ->
        {:error, :not_found}
      execute ->
        {:ok, execute.state}
    end
  end
end
