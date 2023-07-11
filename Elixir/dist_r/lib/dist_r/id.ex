defmodule DistR.Id do
  #module to define unique ids, unused, left in case
  # impementing a login to the web server is desired
  def generate(size \\ 10) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, size)
  end
end
