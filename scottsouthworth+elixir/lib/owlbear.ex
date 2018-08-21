defmodule OwlBear do
  @moduledoc """
  OwlBear handles both the happy paths and the error paths of functions within a single Elixir pipeline.

  A terribly conflicted creature, light and free like an `{:ok, owl}`, heavy and brutal
  like an angry `{:error, bear}`.

  ### Run
  _...to run functions on the happy path..._

  Functions are generally expected to return tuples such as `{:ok, value}` or `{error, value}`.

  Functions that don't return a result tuple can be used with keyword option `wrap: true`.
  This will wrap return values in a result tuple of form `{:ok, value}`.

  Functions that generate exceptions can be trapped as error tuples using the option `try: true`.

  Results can be named and referenced later in the pipeline using the option `name: atom()`.

  Normally, the OwlBear just runs along. A result tuple is released when the OwlBears decides to `eol`.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn msg -> msg <> ", let's be friends!" end, wrap: true)
      ...> |> eol()
      {:ok, "Hello OwlBear, let's be friends!"}

  But sometimes, OwlBear runs into trouble (ye olde `:error`).

  This knocks OwlBear down and he'll stop running additional functions in the pipeline.
  His error state is carried forward.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn msg -> {:error, msg <> ", too many bunnies nearby!"} end)
      ...> |> run(fn _ -> {:ok, "We can handle bunnies, right?"} end)
      ...> |> run(fn _ -> {:error, "Run away! Run away!"} end)
      ...> |> eol()
      {:error, "Hello OwlBear, too many bunnies nearby!"}

  Note that the last two functions are skipped because OwlBear is no longer
  travelling on the happy path. An OwlBear must be pretty happy to keep running.

  ### Note
  _...anything that comes along..._

  No matter what's going on, OwlBear can always check things out.
  This could reveal multiple errors, note certain values or cause various side-effects, but
  it won't affect the value passing through OwlBear's pipeline.

  If an error is returned, it will shift OwlBear to the `:error` path, though.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn _ -> {:ok, "A delicious adventuer!"} end, name: :nearby)
      ...> |> run(fn _ -> {:error, "This guy has a sword!"} end, name: :armed)
      ...> |> note(fn _ -> "Not dead yet?" end, wrap: true, name: :dead)
      ...> |> note(fn _ -> {:error, "Run away! Run away!"} end, name: :must_flee)
      ...> |> note(fn _ -> {:ok, "Are we safe now?"} end, name: :safe)
      ...> |> eol()
      {:error, "This guy has a sword!"}

  When OwlBear checks something, he will always pass along the value, but cannot
  recover from the error path.

  ### Fix
  _...to crush the errors in our way..._

  OwlBear can find his way back to the happy path, by taking errors down (fixing the problem).

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> run(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> fix(fn _ -> {:ok, "Adventurer parts are everywhere."} end)
      ...> |> fix(fn _ -> {:ok, "This might be overkill."} end)
      ...> |> fix(fn _ -> {:ok, "I think we got him."} end)
      ...> |> eol()
      {:ok, "Adventurer parts are everywhere."}

  Fixs are only executed when on the `:error` path. A successful fix will bring OwlBear back to the `:ok` world.


  """

  require Logger
  alias OwlBear.{Path, Result, Options}

  @type tag_result :: {:ok | :error, any()}

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value or named map (using the `map` option).
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `wrap: true`, `map: :ok | :error | :result` and `try: true`.

  ## Examples

      iex> import OwlBear
      ...> {:ok, 10}
      ...> |> run(fn x -> x * 2 end, wrap: true)
      ...> |> eol()
      {:ok, 20}
      iex> {:ok, 10}
      ...> |> run(fn x -> {:error, x * 5} end)
      ...> |> eol()
      {:error, 50}
      iex> {:error, 7}
      ...> |> run(fn x -> {:ok, x * 3} end)
      ...> |> eol()
      {:error, 7}
      iex> "OwlBear can"
      ...> |> run(fn x -> x <> " concatenate!" end, wrap: true, name: :concat)
      ...> |> eol()
      {:ok, "OwlBear can concatenate!"}
      iex> {:ok, "OwlBear cannot"}
      ...> |> run(fn x -> x + 5 end, try: true, wrap: true)
      ...> |> eol()
      {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}}
  """

  @spec run(any(), function(), keyword()) :: Path.t()
  def run(path_or_value, function, options \\ [])
      when is_function(function) and is_list(options) do
    resolve_path(path_or_value, function, [path: :ok] ++ options)
  end

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn/x :: {:ok | :error, any()}` by applying arguments created via the
  `notes` array.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `wrap: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      ...> note(bunnies: 3, swords: 2, hats: 7)
      ...> |> run_ok_map(fn m ->  m.bunnies + m.swords * m.hats end, wrap: true)
      ...> |> eol()
      {:ok, 17}
      ...> {:ok, 5}
      ...> |> note(bunnies: 4)
      ...> |> run(fn x -> x * 3 end, name: :more_bunnies, wrap: true)
      ...> |> run_ok_map(fn m -> {:ok, m.bunnies + m.more_bunnies} end)
      ...> |> eol()
      {:ok, 19}
  """

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn(h :: OwlBear.History.t()) :: {:ok | :error, any()}`.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `wrap: true` and `try: true`.

  """

  @doc """
  Operates only on the `:error` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:ok` tuple is returned, the path will shift to the `:ok` state.

  Supports options: `name: atom()`, `wrap: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      iex> {:error, 3}
      ...> |> fix(fn x -> {:ok, x * 2} end)
      ...> |> eol()
      {:ok, 6}
      iex> {:ok, 4}
      ...> |> fix(fn x -> {:ok, x * 5} end)
      ...> |> eol()
      {:ok, 4}
      iex> {:error, 7}
      ...> |> fix(fn x -> {:error, x + 3} end)
      ...> |> eol()
      {:error, 10}
  """

  @spec fix(any(), function(), keyword()) :: Path.t()
  def fix(path, function, options \\ []) do
    resolve_path(path, function, [path: :error, tag: :can_become_ok] ++ options)
  end

  @doc """
  Operates only on the `:error` path.
  Calls the function `fn/x :: {:ok | :error, any()}` by applying arguments created via the
  `notes` array.
  If an `:ok` tuple is returned, the path will shift to the `:ok` state.

  Supports options: `name: atom()`, `wrap: true` and `try: true`.

  ## Examples


      iex> import OwlBear
      ...> {:error, "OwlBear needs a fix."}
      ...> |> note(bunnies: 3, swords: 2, hats: 7)
      ...> |> fix_ok_map(fn m -> {:ok, m.swords} end)
      ...> |> eol()
      {:ok, 2}

  """

  @doc """
  Operates on both the `:ok` and `:error` paths.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  ## Examples

      # check does not affect the pipeline value or track
      iex> import OwlBear
      ...> {:ok, 100}
      ...> |> note(fn x -> {:ok, x * 2} end)
      ...> |> eol()
      {:ok, 100}

      # notes will not change paths even with errors, pipeline value unchanged
      iex> import OwlBear
      ...> {:ok, 200}
      ...> |> note(fn x -> {:ok, x + 5} end)
      ...> |> note(fn x -> {:error, x * 3} end)
      ...> |> note(fn x -> {:ok, x - 4} end)
      ...> |> eol()
      {:ok, 200}

      # can `wrap` returns with `:ok` and `try` functions that throw exceptions
      iex> import OwlBear
      ...> path = {:ok, 300}
      ...> |> note(fn x -> x + 5 end, wrap: true, name: :plus_five)
      ...> |> note(fn x -> {:error, x * 4} end, name: :times_four)
      ...> |> note(fn x -> {:ok, x - 6} end, name: :minus_six)
      ...> |> note(fn x -> x / (x - 300) end, wrap: true, try: true, name: :division)
      ...> path |> eol()
      {:ok, 300}

      # can view `:ok` pipeline results by `name`
      iex> import OwlBear
      ...> path = {:ok, 300}
      ...> |> note(fn x -> x + 5 end, wrap: true, name: :plus_five)
      ...> |> note(fn x -> {:error, x * 4} end, name: :times_four)
      ...> |> note(fn x -> {:ok, x - 6} end, name: :minus_six)
      ...> |> note(fn x -> x / (x - 300) end, wrap: true, try: true, name: :division)
      ...> path |> eol(map: :ok)
      %{minus_six: 294, plus_five: 305}

      # can view `:error` pipeline results by `name`
      iex> import OwlBear
      ...> path = {:ok, 300}
      ...> |> note(fn x -> x + 5 end, wrap: true, name: :plus_five)
      ...> |> note(fn x -> {:error, x * 4} end, name: :times_four)
      ...> |> note(fn x -> {:ok, x - 6} end, name: :minus_six)
      ...> |> note(fn x -> x / (x - 300) end, wrap: true, try: true, name: :division)
      ...> path |> eol(map: :error)
      %{
        division: %ArithmeticError{message: "bad argument in arithmetic expression"},
        times_four: 1200
      }

      # can view full result tuple pipeline results by `name`
      iex> import OwlBear
      ...> path = {:ok, 300}
      ...> |> note(fn x -> x + 5 end, wrap: true, name: :plus_five)
      ...> |> note(fn x -> {:error, x * 4} end, name: :times_four)
      ...> |> note(fn x -> {:ok, x - 6} end, name: :minus_six)
      ...> |> note(fn x -> x / (x - 300) end, wrap: true, try: true, name: :division)
      ...> path |> eol(map: :result)
      %{
        division: {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}},
        minus_six: {:ok, 294},
        plus_five: {:ok, 305},
        times_four: {:error, 1200}
      }


  """

  @spec note(Path.t(), function(), keyword()) :: Path.t()
  def note(path, function, options \\ []) when is_function(function) and is_list(options) do
    resolve_path(
      path,
      function,
      options ++ [path: :ok, tag: :stays_the_same, value: :stays_the_same]
    )
  end

  @spec alert(Path.t(), function(), keyword()) :: Path.t()
  def alert(path, function, options \\ []) when is_function(function) and is_list(options) do
    resolve_path(
      path,
      function,
      options ++ [path: :error, tag: :stays_the_same, value: :stays_the_same]
    )
  end

  @spec pack(keyword()) :: Path.t()
  def pack(key_values) when is_list(key_values) do
    case Keyword.keyword?(key_values) do
      true -> to_path({:ok, nil}) |> add_key_value_list_elements(key_values)
      false -> raise "Can only `OwlBear.pack` key names of type `atom()`."
    end
  end

  @doc """
  Ends the pipeline and returns a result tuple of the form `{:ok | :error, any()}`.

  ## Examples
      iex> import OwlBear
      ...> {:ok, 5}
      ...> |> run(fn x -> x * 3 end, wrap: true)
      ...> |> eol()
      {:ok, 15}

  """

  @spec eol(Path.t()) :: tag_result()
  def eol(%Path{} = path, options \\ []) do
    new_options = to_options(options)

    case new_options.map do
      :none -> {path.result.tag, path.result.value}
      _ -> get_result_map(path, new_options.map)
    end
  end

  # internal

  defp get_result_map(path, map_type) do
    results =
      path.history
      |> Enum.filter(fn r ->
        r.name != nil and r.skip == false and (map_type == :result or r.tag == map_type)
      end)

    case map_type do
      :result -> Enum.map(results, fn r -> {r.name, {r.tag, r.value}} end)
      _ -> Enum.map(results, fn r -> {r.name, r.value} end)
    end
    |> Enum.reverse()
    |> Map.new()
  end

  defp resolve_path(path_or_value, function, options_or_keywords) do
    path = to_path(path_or_value)
    options = to_options(options_or_keywords)
    on_path = is_on_path?(path.result, options)

    case on_path do
      true -> resolve_on_path(path, function, options)
      false -> path
    end
  end

  defp resolve_on_path(%Path{} = path, function, %Options{} = options) do
    new_function =
      case options.map do
        :none -> function
        _ -> outside_pipeline_function(function, get_result_map(path, options.map))
      end

    new_result = resolve_function(path.result, new_function, options)
    new_history = [new_result | path.history]
    pipeline_tag = resolve_tag(path.result.tag, new_result.tag, options.tag)
    pipeline_value = resolve_value(path.result.value, new_result.value, options.value)
    pipeline_result = %Result{new_result | tag: pipeline_tag, value: pipeline_value}
    %Path{result: pipeline_result, history: new_history}
  end

  defp is_on_path?(%Result{tag: tag}, %Options{path: path}) do
    case {tag, path} do
      {:error, :error} -> true
      {:ok, :ok} -> true
      {_, :both} -> true
      _ -> false
    end
  end

  defp on_known_path?(%Options{path: path}) do
    case path do
      :both -> false
      _ -> true
    end
  end

  defp resolve_function(%Result{} = result, function, %Options{name: name, try: true} = options) do
    try do
      resolve_function_input(result, function, options)
    rescue
      e -> %Result{tag: :error, name: name, value: e}
    end
  end

  defp resolve_function(%Result{} = result, function, %Options{try: false} = options) do
    resolve_function_input(result, function, options)
  end

  defp resolve_function_input(
         %Result{} = result,
         function,
         %Options{} = options
       ) do
    function_return = function.(result.value)
    resolve_function_return(result, function_return, options)
  end

  defp resolve_function_return(%Result{tag: tag} = result, value, %Options{} = options) do
    {new_tag, new_value} =
      case options.wrap do
        true ->
          {:ok, value}

        false ->
          case value do
            {:ok, _} ->
              value

            {:error, _} ->
              value

            _ ->
              raise(
                "Return value for function via name #{inspect(options.name)} must be of the form {:ok | :error, any()}."
              )
          end
      end

    %Result{tag: new_tag, name: options.name, value: new_value}
  end

  defp resolve_value(old_value, new_value, value_control) do
    case value_control do
      :stays_the_same -> old_value
      :can_change -> new_value
    end
  end

  defp resolve_tag(old_tag, new_tag, tag_control) do
    case tag_control do
      :can_become_error ->
        case new_tag do
          :error -> :error
          :ok -> old_tag
        end

      :stays_the_same ->
        old_tag

      :can_become_ok ->
        case new_tag do
          :ok -> :ok
          :error -> old_tag
        end
    end
  end

  # to use stored values instead of the current pipeline value
  defp outside_pipeline_function(function, argument) do
    fn _pipeline_value -> function.(argument) end
  end

  defp add_key_value_list_elements(%Path{} = path, [{k, v} | key_values]) do
    new_result = %Result{name: k, value: v}
    new_history = [new_result | path.history]
    new_path = %Path{result: new_result, history: new_history}
    add_key_value_list_elements(new_path, key_values)
  end

  defp add_key_value_list_elements(%Path{} = path, []) do
    path
  end

  defp to_options(%Options{} = options) do
    options
  end

  defp to_options(list) when is_list(list) do
    true = Keyword.keyword?(list)
    Enum.reduce(list, %Options{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp to_path(%Path{} = path) do
    path
  end

  defp to_path({tag, value}) when tag == :ok or tag == :error do
    %Path{result: %Result{tag: tag, value: value}}
  end

  defp to_path(value) do
    %Path{result: %Result{tag: :ok, value: value}}
  end
end
