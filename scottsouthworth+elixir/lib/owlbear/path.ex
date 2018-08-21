defmodule OwlBear.Path do
  alias OwlBear.{Result, Path}
  @moduledoc false

  defstruct result: %Result{}, history: []

  @type t :: %Path{
          result: Result.t(),
          history: [Result.t()]
        }
end

#
# iex> import OwlBear
# ...> ponder(bunnies: 3, swords: 2, hats: 7)
# ...> |> run_using(fn x, y, z -> {:ok, x + y * z} end, [:bunnies, :swords, :hats])
# ...> |> rest()
# {:ok, 17}
# ...> ponder(bunnies: 4)
# ...> |> run!(fn x -> x * 3 end, :more_bunnies)
# ...> |> run_using(fn x, y -> {:ok, x + y} end, [:bunnies, :more_bunnies])
# ...> |> rest()
# {:ok, 16}
