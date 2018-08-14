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

  defdelegate note(key_values), to: OwlBear, as: :note
  defdelegate note(path, key_values), to: OwlBear, as: :note
  defdelegate rest(path), to: OwlBear, as: :eol

  defdelegate attack(path, function, options \\ []), to: OwlBear, as: :run
  defdelegate attack_oks(path, function, notes, options \\ []), to: OwlBear, as: :run_oks
  defdelegate attack_errors(path, function, options \\ []), to: OwlBear, as: :run_errors
  defdelegate attack_results(path, function, options \\ []), to: OwlBear, as: :run_results

  defdelegate peck(path, function, options \\ []), to: OwlBear, as: :check
  defdelegate peck_oks(path, function, notes, options \\ []), to: OwlBear, as: :check_oks
  defdelegate peck_errors(path, function, options \\ []), to: OwlBear, as: :check_errors
  defdelegate peck_results(path, function, options \\ []), to: OwlBear, as: :check_results

  defdelegate hug(path, function, options \\ []), to: OwlBear, as: :fix
  defdelegate hug_using(path, function, notes, options \\ []), to: OwlBear, as: :fix_using
  defdelegate hug_history(path, function, options \\ []), to: OwlBear, as: :fix_history

end
