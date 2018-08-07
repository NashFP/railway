defmodule OwlBear.Path do
  alias OwlBear.{Result, Path}
  @moduledoc false

  defstruct result: %Result{}, history: []

  @type t :: %Path{
          result: Result.t(),
          history: [Result.t()]
        }
end
