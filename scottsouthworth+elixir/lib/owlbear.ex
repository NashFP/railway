defmodule OwlBear do
  @moduledoc """
  OwlBear handles both the happy paths and the error paths of functions within a single Elixir pipeline.

  But the poor OwlBear is a terribly conflicted creature, light and free like an `{:ok, owl}`, heavy and brutal
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

  ### Check
  _...anything that comes along..._

  OwlBear is always ready to grab a bite. No matter what's going on, he can always check.
  This could make him sick, though, wracking up multiple errors.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> check(fn _ -> {:ok, "A delicious adventuer!"} end, name: :nearby)
      ...> |> check(fn _ -> {:error, "This guy has a sword!"} end, name: :armed)
      ...> |> check(fn _ -> "Not dead yet?" end, wrap: true, name: :dead)
      ...> |> check(fn _ -> {:error, "Run away! Run away!"} end, name: :must_flee)
      ...> |> check(fn _ -> {:ok, "Are we safe now?"} end, name: :safe)
      ...> |> eol()
      {:error, "Hello OwlBear"}

  When OwlBear checks something, he will always pass along the value, but cannot
  recover from the error path.

  ### Fix
  _...to crush the errors in our way..._

  OwlBear can find his way back to the happy path, by taking errors down (fixing the problem).

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> check(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> check(fn _ -> {:error, "This guy has a sword!"} end)
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
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `wrap: true` and `try: true`.

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
  def run(path_or_value, function, options \\ []) do
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

  @spec run_ok_map(any(), function(), keyword()) :: Path.t()
  def run_ok_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :ok, map: :ok] ++ options)
  end

  @spec run_error_map(any(), function(), keyword()) :: Path.t()
  def run_error_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :ok, map: :error] ++ options)
  end

  @spec run_result_map(any(), function(), keyword()) :: Path.t()
  def run_result_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :ok, map: :result] ++ options)
  end

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

  #      ...> note(bunnies: 4)
  #      ...> |> run(fn x -> x * 3 end, name: :more_bunnies, wrap: true)
  #      ...> |> run_using(fn v -> {:ok, v.bunnies + v.more_bunnies} end, [:bunnies, :more_bunnies])
  #      ...> |> eol()
  #      {:ok, 16}

  @spec fix_ok_map(any(), function(), keyword()) :: Path.t()
  def fix_ok_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :error, map: :ok, tag: :can_become_ok] ++ options)
  end

  @spec fix_error_map(any(), function(), keyword()) :: Path.t()
  def fix_error_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :error, map: :error, tag: :can_become_ok] ++ options)
  end

  @spec fix_result_map(any(), function(), keyword()) :: Path.t()
  def fix_result_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :error, map: :result, tag: :can_become_ok] ++ options)
  end




  @doc """
  Operates on both the `:ok` and `:error` paths.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  ## Examples
      iex> import OwlBear
      iex> {:ok, 300}
      ...> |> check(fn x -> {:ok, x * 2} end)
      ...> |> eol()
      {:ok, 300}
      iex> {:ok, 4}
      ...> |> check(fn x -> {:error, x * 5} end)
      ...> |> eol()
      {:error, 4}
      iex> {:error, 7}
      ...> |> check(fn x -> {:ok, x * 2} end)
      ...> |> check(fn x -> {:error, x + 3} end)
      ...> |> eol()
      {:error, 7}
  """

  @spec check(any(), function(), keyword()) :: Path.t()
  def check(path, function, options \\ []) do
    resolve_path(path, function, [path: :both, tag: :can_become_error, value: :stays_the_same] ++ options)
  end

  @spec check_ok_map(any(), function(), keyword()) :: Path.t()
  def check_ok_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :both, map: :ok, tag: :can_become_error, value: :stays_the_same] ++ options)
  end

  @spec check_error_map(any(), function(), keyword()) :: Path.t()
  def check_error_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :both, map: :error, tag: :can_become_error, value: :stays_the_same] ++ options)
  end

  @spec check_result_map(any(), function(), keyword()) :: Path.t()
  def check_result_map(path, function, options \\ []) do
    resolve_path(path, function, [path: :both, map: :result, tag: :can_become_error, value: :stays_the_same] ++ options)
  end


  @spec note(keyword()) :: Path.t()
  def note(key_values) do
    to_path({:ok,nil}) |> do_memorize_many(key_values)
  end

  @spec note(Path.t(), keyword()) :: Path.t()
  def note(%Path{} = path, key_values) do
    path |> do_memorize_many(key_values)
  end

  @spec note(any(), keyword()) :: Path.t()
  def note(value, key_values) do
    to_path(value) |> do_memorize_many(key_values)
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
  def eol(%Path{} = path) do
    {path.result.tag, path.result.value}
  end

  # internal

  defp get_result_map(path, map_type) do
    results = path.history
              |> Enum.filter(fn r -> r.name != nil and r.skip == false and (map_type == :result or r.tag == map_type) end)

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
    %Path{result: new_result, history: new_history}
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
        true -> {:ok, value}
        false ->
          case value do
            {:ok, _value} -> value
            {:error, _value} -> value
            _ -> raise("Return value for function via name #{inspect(options.name)} must be of the form {:ok | :error, any()}.")
          end
      end

    final_value = resolve_value(result.value, new_value, options.value)
    final_tag = resolve_tag(tag, new_tag, options.tag)
    %Result{tag: final_tag, name: options.name, value: final_value}
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

  # adds key-values to the path history with current pipeline result unchanged
  defp do_memorize_many(%Path{} = path, key_values) do
    new_path = add_key_value_list_elements(path, key_values)
    new_history = [path.result | new_path.history]
    %Path{result: path.result, history: new_history}
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

  # run, check, fix, note, eol, signal vs alert

end
