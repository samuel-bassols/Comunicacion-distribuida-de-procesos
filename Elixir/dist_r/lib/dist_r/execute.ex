defmodule DistR.Execute do
  alias __MODULE__
  # Defines the data struc Execute
  @pending_state :pending
  @processing_state :processing
  @error_state :error
  @ready_state :ready
  @sleep_state :sleep

  @type state :: :pending | :processing | :error | :ready |:sleep

  @type t :: %Execute{
          token: String.t(),
          state: state,
          start_time: DateTime.Calendar,
          end_time: DateTime.Calendar,
          node: String.t(),
          user: String.t()
        }

  @enforce_keys [:token, :state]

  defstruct [
    :token,
    :state,
    :start_time,
    :end_time,
    :node,
    :user
  ]
  #Create a new Execute
  def new(params) do
    with {:ok, token} <- Keyword.fetch(params, :token) do
      {:ok, user} =Keyword.fetch(params, :user)
      %Execute{
        token: token,
        state: @pending_state,
        start_time: DateTime.truncate(DateTime.utc_now, :second),
        end_time: nil,
        node: node(),
        user: user
      }
    end
  end
  # Functions to obtain the different states of Execution
  def pending_state, do: @pending_state
  def processing_state, do: @processing_state
  def error_state, do: @error_state
  def ready_state, do: @ready_state
  def sleep_state, do: @sleep_state
  #Functions that change the state of an Execution
  def with_pending_state(%Execute{} = execute) do
    %{execute | state: @pending_state}
  end

  def with_processing_state(%Execute{} = execute) do
    %{execute | state: @processing_state}
  end

  def with_ready_state(%Execute{} = execute) do
    %{execute | state: @ready_state}
  end
  def with_error_state(%Execute{} = execute) do
    %{execute | state: @error_state}
  end

  def with_sleep_state(%Execute{} = execute) do
    %{execute | state: @sleep_state}
  end
  #Function that changes the end time of an Execution
  def with_end_time(%Execute{} = execute) do
    %{execute | end_time: DateTime.truncate(DateTime.utc_now, :second)}
  end
  #Function that changes the node that an Execution says its using
  def with_node(%Execute{} = execute) do
    %{execute | node: node()}
  end


  def sleep?(%Execute{state: state}), do: state == @sleep_state

  def get_token(%Execute{token: token}) do
    token
  end
end
