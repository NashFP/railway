defmodule OwlBear.ROP do

  @moduledoc """
  ROP
  """


  @doc """
  Calls the function `fn/1 :: any()` as a side-effect from either track.

  The return value is ignored and the track will remain unchanged.

  ## Examples
      iex> import OwlBear.ROP
      iex> "low"
      ...> |> signal(fn x -> IO.puts("danger " <> x) end)
      ...> |> eol()
      {:ok, "low"}

      iex> import OwlBear.ROP
      iex> {:error, "high"}
      ...> |> signal(fn x -> IO.puts("danger " <> x) end)
      ...> |> eol()
      {:error, "high"}

  Note that "danger low" and then "danger high" would be output for these examples, respectively.
  """

  defdelegate signal(track, function, options \\ []), to: OwlBear, as: :growl

  @doc """
  eol
  """
  defdelegate note(track), to: OwlBear, as: :rest
  defdelegate eol(track), to: OwlBear, as: :rest
  defdelegate signal_history(track), to: OwlBear, as: :growl
  defdelegate history(track), to: OwlBear, as: :growl

  defdelegate run(track), to: OwlBear, as: :run
  defdelegate run!(track), to: OwlBear, as: :run!
  defdelegate run_using(track), to: OwlBear, as: :run_using
  defdelegate run_using!(track), to: OwlBear, as: :run_using!

  defdelegate check(track), to: OwlBear, as: :eat
  defdelegate check!(track), to: OwlBear, as: :eat!
  defdelegate check_using(track), to: OwlBear, as: :eat_using
  defdelegate check_using!(track), to: OwlBear, as: :eat_using!

  defdelegate fix(track), to: OwlBear, as: :hug
  defdelegate fix!(track), to: OwlBear, as: :hug!
  defdelegate fix_using(track), to: OwlBear, as: :hug_using
  defdelegate fix_using!(track), to: OwlBear, as: :hug_using!

end
