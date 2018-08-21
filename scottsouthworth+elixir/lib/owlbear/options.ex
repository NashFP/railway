defmodule OwlBear.Options do
  @moduledoc false

  defstruct name: nil,
            # use try_catch
            try: false,
            # wrap return value as {:ok, any()}
            wrap: false,
            tag: :can_become_error,
            value: :can_change,
            path: :both,
            map: :none

  @type path_options :: :ok | :error | :both
  @type tag_options :: :can_become_ok | :can_become_error | :stays_the_same
  @type value_options :: :can_change | :stays_the_same
  @type map_options :: :none | :ok | :error | :result

  @type t :: %OwlBear.Options{
          name: atom | nil,
          try: boolean,
          wrap: boolean,
          tag: tag_options(),
          path: path_options()
        }
end
