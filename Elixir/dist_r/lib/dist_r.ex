defmodule DistR do
  #API that abstracts the functionality of the aplication logic
  defdelegate start_execute(token,user), to: DistR.Execute.Tracker, as: :start
  defdelegate is_ready(token), to: DistR.Execute.Queue, as: :get_status

  defdelegate get_table(), to: DistR.Execute.Queue, as: :get_cache
end
