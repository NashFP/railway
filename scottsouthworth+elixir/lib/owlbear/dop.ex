defmodule OwlBear.DOP do

  @moduledoc """
  DOP
  """


#  @doc """
#  Calls the function `fn/1 :: any()` as a side-effect from either track.
#
#  The return value is ignored and the track will remain unchanged.
#
#  ## Examples
#      iex> import OwlBear.DOP
#      iex> "low"
#      ...> |> growl(fn x -> IO.puts("danger " <> x) end)
#      ...> |> rest()
#      {:ok, "low"}
#
#      iex> import OwlBear.DOP
#      iex> {:error, "high"}
#      ...> |> growl(fn x -> IO.puts("danger " <> x) end)
#      ...> |> rest()
#      {:error, "high"}
#
#  Note that "danger low" and then "danger high" would be output for these examples, respectively.
#  """
#
#  @doc """
#  eol
#  """
  defdelegate note(key_values), to: OwlBear, as: :note
  defdelegate note(track, key_values), to: OwlBear, as: :note
  defdelegate rest(track), to: OwlBear, as: :eol

  defdelegate growl(track, function, options \\ []), to: OwlBear, as: :signal
  defdelegate growl_using(track, function, notes, options \\ []), to: OwlBear, as: :signal_using
  defdelegate growl_history(track, function, options \\ []), to: OwlBear, as: :signal_history

  defdelegate run(track, function, options \\ []), to: OwlBear, as: :run
  defdelegate run_using(track, function, notes, options \\ []), to: OwlBear, as: :run_using
  defdelegate run_history(track, function, options \\ []), to: OwlBear, as: :run_history

  defdelegate eat(track, function, options \\ []), to: OwlBear, as: :check
  defdelegate eat_using(track, function, notes, options \\ []), to: OwlBear, as: :check_using
  defdelegate eat_history(track, function, options \\ []), to: OwlBear, as: :check_history

  defdelegate hug(track, function, options \\ []), to: OwlBear, as: :fix
  defdelegate hug_using(track, function, notes, options \\ []), to: OwlBear, as: :fix_using
  defdelegate hug_history(track, function, options \\ []), to: OwlBear, as: :fix_history

end
