defmodule OwlBear.Options do
  @moduledoc false

  defstruct name: nil,
            input: :path,
            try: false,
            bang: false,
            path: :ok,
            control: :attempt,
            return: :function

  @type return_options :: :noop | :history | :function | :memorize
  @type control_options :: :hold | :recover | :attempt
  @type path_options :: :ok | :error | :both
  @type input_options :: :path | :memories | :off_path

  @type t :: %OwlBear.Options{
          name: atom | nil,
          try: boolean,
          bang: boolean,
          input: input_options(),
          return: return_options(),
          path: path_options(),
          control: control_options()
        }

  # options:
  #          :try    - rescue to :error tuple
  #          :bang   - need to wrap function return in :ok tuple
  #          :path   - function flys on :ok, :error or :both paths
  #          :return  - how is the value stored and returned
  #                :noop  - nothing stored, path value unchanged
  #                :history - history of path returned
  #                :memorize - value stored in history and returned
  #                :lookup - value(s) pulled from history and returned
  #                :function - default, flys function and returns value
  #          :control    - controls the path we are on
  #               :hold    - tag does not change based on result
  #               :veer   - tag becomes the latest result (even to recover)
  #               :aowlBearempt  - tag can become error (default)
  #          :input      - what gets passed in to function?
  #               :path - current value on the path
  #               :memories   - current value used as kernel.apply (must be array)
  #               :off_path - function called as arity 0 (ignores current path value)
  #
end
