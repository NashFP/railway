defmodule OwlBear.Options do
  @moduledoc false

  defstruct name: nil,
            try: false,
            raw: false,
            apply: false,
            path: :both,
            control: :attempt,
            action: :function

  @type action_options :: :function | :value
  @type control_options :: :hold | :recover | :attempt
  @type path_options :: :ok | :error | :both

  @type t :: %OwlBear.Options{
          name: atom | nil,
          try: boolean,
          raw: boolean,
          apply: boolean,
          action: action_options(),
          path: path_options(),
          control: control_options()
        }

  # options:
  #          :try    - rescue to :error tuple
  #          :raw   - need to wrap function return in :ok tuple
  #          :path   - :ok, :error or :both paths
  #          :action  - how is the value stored and returned
  #                :value - value stored in history and returned
  #                :function - run function and returns value
  #          :control    - controls the path we are on
  #               :hold    - tag does not change based on result
  #               :recover   - tag becomes the latest result
  #               :attempt  - tag can become error (default)
  #
  #
end
