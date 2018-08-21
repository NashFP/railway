defmodule OwlBear.DOP do
  @moduledoc """

  # Dungeon Oriented Programming

  An alternative API for true OwlBear fanatics, light and free like an `{:ok, owl}`, heavy and brutal
  like an angry `{:error, bear}`.

  ### Growl
  ...to emit side-effects... `signal`

  ### Eat
  ...to consume events on both paths... `check`

  ### Hug
  ...to lovingly crush errors... `fix`

  ### Rest
  ...to return a final result tuple... `eol`

  """

  defdelegate rise(key_values), to: OwlBear, as: :pack
  defdelegate hoot(path, function, options \\ []), to: OwlBear, as: :note
  defdelegate growl(path, function, options \\ []), to: OwlBear, as: :alert
  defdelegate slumber(path), to: OwlBear, as: :eol
  defdelegate run(path, function, options \\ []), to: OwlBear, as: :run
  defdelegate attack(path, function, options \\ []), to: OwlBear, as: :fix
end
