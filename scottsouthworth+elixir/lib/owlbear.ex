defmodule OwlBear do
  @moduledoc """
  OwlBear handles both the happy paths and the error paths of functions within a single Elixir pipeline.

  But the poor OwlBear is a terribly conflicted creature, light and free like an `{:ok, owl}`, heavy and brutal
  like an angry `{:error, bear}`.

  ### Run
  _...to run functions on the happy path..._

  Functions are generally expected to return tuples such as `{:ok, value}` or `{error, value}`.

  Functions that don't return a result tuple can be used with keyword option `bare: true`.
  This will wrap return values in a result tuple of form `{:ok, value}`.

  Functions that generate exceptions can be trapped as error tuples using the option `try: true`.

  Results can be named and referenced later in the pipeline using the option `name: atom()`.

  Normally, the OwlBear just runs along. A result tuple is released when the OwlBears decides to `rest`.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn msg -> msg <> ", let's be friends!" end, bare: true)
      ...> |> rest()
      {:ok, "Hello OwlBear, let's be friends!"}

  But sometimes, OwlBear runs into trouble (ye olde `:error`).

  This knocks OwlBear down and he'll stop running additional functions in the pipeline.
  His error state is carried forward.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn msg -> {:error, msg <> ", too many bunnies nearby!"} end)
      ...> |> run(fn msg -> {:ok, "We can handle bunnies, right?"} end)
      ...> |> run(fn msg -> {:error, "Run away! Run away!"} end)
      ...> |> rest()
      {:error, "Hello OwlBear, too many bunnies nearby!"}

  Note that the last two functions are skipped because OwlBear is no longer
  travelling on the happy path. An OwlBear must be pretty happy to keep running.

  ### Eat
  _...anything that comes along..._

  OwlBear is always ready to grab a bite. No matter what's going on, he can always eat.
  This could make him sick, though, wracking up multiple errors.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> eat(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> eat(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> eat(fn _ -> "Not dead yet?" end, bare: true)
      ...> |> eat(fn _ -> {:error, "Run away! Run away!"} end)
      ...> |> eat(fn _ -> {:ok, "Are we safe now?"} end)
      ...> |> rest()
      {:error, "Are we safe now?"}

  When OwlBear eats something, he will always pass along the value, but cannot
  recover from the error path.

  ### Hug
  _...to crush the errors in our way..._

  OwlBear can find his way back to the happy path, by taking errors down (huging the problem).

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> eat(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> eat(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> hug(fn _ -> {:ok, "Adventurer parts are everywhere."} end)
      ...> |> hug(fn _ -> {:ok, "This might be overkill."} end)
      ...> |> hug(fn _ -> {:ok, "I think we got him."} end)
      ...> |> rest()
      {:ok, "Adventurer parts are everywhere."}

  Hugs are only executed when on the `:error` path. A successful hug will bring OwlBear back to the `:ok` world.


  """

  require Logger
  alias OwlBear.{Path, Result, Options, History}

  @type tag_result :: {:ok | :error, any()}
  @type memories :: [atom()]

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      ...> {:ok, 10}
      ...> |> run(fn x -> x * 2 end, bare: true)
      ...> |> rest()
      {:ok, 20}
      iex> {:ok, 10}
      ...> |> run(fn x -> {:error, x * 5} end)
      ...> |> rest()
      {:error, 50}
      iex> {:error, 7}
      ...> |> run(fn x -> {:ok, x * 3} end)
      ...> |> rest()
      {:error, 7}
      iex> "OwlBear can"
      ...> |> run(fn x -> x <> " concatenate!" end, bare: true, name: :concat)
      ...> |> rest()
      {:ok, "OwlBear can concatenate!"}
      iex> {:ok, "OwlBear cannot"}
      ...> |> run(fn x -> x + 5 end, try: true, bare: true)
      ...> |> rest()
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

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      ...> note(bunnies: 3, swords: 2, hats: 7)
      ...> |> run_using(fn x, y, z -> {:ok, x + y * z} end, [:bunnies, :swords, :hats])
      ...> |> rest()
      {:ok, 17}
      ...> note(bunnies: 4)
      ...> |> run(fn x -> x * 3 end, name: :more_bunnies, bare: true)
      ...> |> run_using(fn x, y -> {:ok, x + y} end, [:bunnies, :more_bunnies])
      ...> |> rest()
      {:ok, 16}
  """

  @spec run_using(any(), function(), memories(), keyword()) :: Path.t()
  def run_using(path, function, notes, options \\ []) do
    recall_memories(path, notes)
    |> resolve_path(function, [path: :ok, input: :memories] ++ options)
  end

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn(h :: OwlBear.History.t()) :: {:ok | :error, any()}`.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  """

  @spec run_history(any(), function(), keyword()) :: Path.t()
  def run_history(path, function, options \\ []) do
    recall_history(path)
    |> resolve_path(function, [path: :ok] ++ options)
  end



  @doc """
  Operates only on the `:error` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:ok` tuple is returned, the path will shift to the `:ok` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      iex> {:error, 3}
      ...> |> hug(fn x -> {:ok, x * 2} end)
      ...> |> rest()
      {:ok, 6}
      iex> {:ok, 4}
      ...> |> hug(fn x -> {:ok, x * 5} end)
      ...> |> rest()
      {:ok, 4}
      iex> {:error, 7}
      ...> |> hug(fn x -> {:error, x + 3} end)
      ...> |> rest()
      {:error, 10}
  """

  @spec hug(any(), function(), keyword()) :: Path.t()
  def hug(path, function, options \\ []) do
    resolve_path(path, function, [path: :error, control: :recover] ++ options)
  end

  @doc """
  Operates only on the `:error` path.
  Calls the function `fn/x :: {:ok | :error, any()}` by applying arguments created via the
  `notes` array.
  If an `:ok` tuple is returned, the path will shift to the `:ok` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  ## Examples
      iex> import OwlBear
      ...> {:error, "OwlBear needs a hug."}
      ...> |> note(bunnies: 3, swords: 2, hats: 7)
      ...> |> hug_using(fn x, y, z -> {:ok, x + y * z} end, [:bunnies, :swords, :hats])
      ...> |> rest()
      {:ok, 17}
      ...> note(bunnies: 4)
      ...> |> run(fn x -> x * 3 end, name: :more_bunnies, bare: true)
      ...> |> run_using(fn x, y -> {:ok, x + y} end, [:bunnies, :more_bunnies])
      ...> |> rest()
      {:ok, 16}
  """

  @spec hug_using(any(), function(), memories(), keyword()) :: Path.t()
  def hug_using(path, function, notes, options \\ []) do
    recall_memories(path, notes)
    |> resolve_path(function, [input: :memories, path: :error, control: :recover] ++ options)
  end

  @doc """
  Operates only on the `:error` path.
  Calls the function `fn(h :: OwlBear.History.t()) :: {:ok | :error, any()}`.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  """

  @spec hug_history(any(), function(), keyword()) :: Path.t()
  def hug_history(path, function, options \\ []) do
    path |> resolve_path(function, [path: :error, return: :history, control: :recover] ++ options)
  end



  @doc """
  Operates on both the `:ok` and `:error` paths.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  ## Examples
      iex> import OwlBear
      iex> {:error, 3}
      ...> |> eat(fn x -> {:ok, x * 2} end)
      ...> |> rest()
      {:error, 6}
      iex> {:ok, 4}
      ...> |> eat(fn x -> {:ok, x * 5} end)
      ...> |> rest()
      {:ok, 20}
      iex> {:error, 7}
      ...> |> eat(fn x -> {:ok, x * 2} end)
      ...> |> eat(fn x -> {:error, x + 3} end)
      ...> |> rest()
      {:error, 17}
  """

  @spec eat(any(), function(), keyword()) :: Path.t()
  def eat(path, function, options \\ []) do
    resolve_path(path, function, options)
  end

  @doc """
  Operates on both the `:ok` and `:error` paths.
  Calls the function `fn/x :: {:ok | :error, any()}` by applying arguments created via the
  `notes` array.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  ## Examples
      iex> import OwlBear
      ...> note(bunnies: 3, swords: 2, hats: 7)
      ...> |> eat_using(fn x, y, z -> {:ok, x + y * z} end, [:bunnies, :swords, :hats])
      ...> |> rest()
      {:ok, 17}
      ...> note(bunnies: 4)
      ...> |> eat(fn x -> x * 3 end, name: :more_bunnies, bare: true)
      ...> |> eat_using(fn x, y -> {:ok, x + y} end, [:bunnies, :more_bunnies])
      ...> |> rest()
      {:ok, 16}
  """

  @spec eat_using(any(), function(), memories(), keyword()) :: Path.t()
  def eat_using(path, function, notes, options \\ []) do
    recall_memories(path, notes)
    |> resolve_path(function, [input: :memories] ++ options)
  end

  @doc """
  Operates on both the `:ok` and `:error` paths.
  Calls the function `fn(h :: OwlBear.History.t()) :: {:ok | :error, any()}`.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  Supports options: `name: atom()`, `bare: true` and `try: true`.

  """

  @spec eat_history(any(), function(), keyword()) :: Path.t()
  def eat_history(path, function, options \\ []) do
    path |> resolve_path(function, [return: :history] ++ options)
  end



  @doc """
  Calls the function `fn/1 :: any()` as a side-effect using the current path value.
  Operates on both the `:error` and `:ok` paths unless specified with the `path: :ok | :error` option.

  The return value is ignored and the path will remain unchanged.

  ## Examples
      iex> import OwlBear
      ...> {:ok, "low"}
      ...> |> growl(fn x -> IO.puts("danger " <> x) end)
      ...> |> rest()
      {:ok, "low"}
      ...> {:error, "high"}
      ...> |> growl(fn x -> IO.puts("danger " <> x) end, path: :error)
      ...> |> rest()
      {:error, "high"}

  Supports options: `name: atom()`, `try: true`, and `path: :ok | :error`.

  """

  @spec growl(Path.t(), function(), keyword()) :: Path.t()
  def growl(path, function, options \\ []) do
    resolve_path(path, function, [bare: true] ++ options)
    to_path(path)
  end


  @spec growl_using(any(), function(), memories(), keyword()) :: Path.t()
  def growl_using(path, function, notes, options \\ []) do
    recall_memories(path, notes)
    |> resolve_path(function, [bare: true, input: :memories] ++ options)
    to_path(path)
  end


  @doc """
  Calls the function `fn(h :: OwlBear.History.t()) :: {:ok | :error, any()}` as a side-effect.
  Operates on both the `:error` and `:ok` paths unless specified with the `path: :ok | :error` option.

  The return value is ignored and the path will remain unchanged.

  Supports options: `name: atom()`, `try: true`, and `path: :ok | :error`.
  """

  @spec growl_history(Path.t(), function(), keyword()) :: Path.t()
  def growl_history(path, function, options \\ []) do
    recall_history(path)
    |> resolve_path(function, [bare: true] ++ options)
    to_path(path)
  end

  @spec note(keyword()) :: Path.t()
  def note(key_values) do
    to_path({:ok,nil}) |> do_memorize_many(key_values)
  end

  @spec note(any(), keyword()) :: Path.t()
  def note(path, key_values) do
    path |> do_memorize_many(key_values)
  end

  @doc """
  Ends the pipeline and returns a result tuple of the form `{:ok | :error, any()}`.

  ## Examples
      iex> import OwlBear
      ...> {:ok, 5}
      ...> |> run(fn x -> x * 3 end, bare: true)
      ...> |> rest()
      {:ok, 15}

  """

  @spec rest(Path.t()) :: tag_result()
  def rest(%Path{} = path) do
    {path.result.tag, path.result.value}
  end

  # internal

  @spec recall_history(Path.t()) :: Path.t()
  defp recall_history(path) do
    note(path, [{nil, path.history}])
  end


  @spec recall_memories(Path.t(), memories()) :: Path.t()
  defp recall_memories(path, memories) do
    note(path, [{nil, extract_raw_values(path, memories)}])
  end

  defp extract_ok_values(path, memory_names) do
    extract_results(path, memory_names)
    |> Enum.map(&Result.result_to_ok_value/1)
  end

  defp extract_raw_values(path, memory_names) do
    extract_results(path, memory_names)
    |> Enum.map(fn r -> r.value end)
  end

  defp extract_results(path, memory_names) do
    Enum.map(
      memory_names,
      fn name ->
        %Result{} =
          Enum.find(path.history, {:error, :memory_not_found}, fn r ->
            r.name == name and r.skip == false
          end)
      end
    )
  end

  defp resolve_path(function, options_or_keywords) do
    resolve_path(to_path({:ok, nil}), function, options_or_keywords)
  end

  defp resolve_path(path_or_value, function, options_or_keywords) do
    path = to_path(path_or_value)
    options = to_options(options_or_keywords)
    on_path = is_on_path?(path.result, options)

    case on_path do
      true -> resolve_on_path(path, function, options)
      false -> resolve_off_path(path, function, options)
    end
  end

  defp resolve_on_path(%Path{} = path, function, %Options{} = options) do
    new_result =
      case options.return do
        :history ->
          history_result = %Result{path.result | value: path.history, name: nil}
          resolve_function(history_result, function, options)

        :function ->
          resolve_function(path.result, function, options)

        :noop ->
          resolve_function(path.result, function, options)
          %Result{path.result | skip: true, name: nil}

        :history_noop ->
          history_result = %Result{path.result | value: path.history, name: nil}
          resolve_function(history_result, function, options)
          %Result{path.result | skip: true, name: nil}

        :memorize ->
          resolve_direct_value(path.result, function, options)
      end

    new_history = [new_result | path.history]
    %Path{result: new_result, history: new_history}
  end

  defp resolve_off_path(%Path{} = path, _function, %Options{} = options) do
    skip_result = %Result{path.result | skip: true, name: options.name}
    new_history = [skip_result | path.history]
    %Path{result: path.result, history: new_history}
  end

  defp is_on_path?(%Result{tag: tag}, %Options{path: path}) do
    case {tag, path} do
      {:error, :error} -> true
      {:ok, :ok} -> true
      {_, :both} -> true
      _ -> false
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
         %Result{value: value} = result,
         function,
         %Options{name: name, input: :memories} = options
       ) do
    case is_list(value) do
      true ->
        function_return = apply(function, value)
        resolve_function_return(result, function, function_return, options)

      false ->
        %Result{tag: :error, name: name, value: :cannot_apply_non_list_value}
    end
  end

  defp resolve_function_input(
         %Result{value: value} = result,
         function,
         %Options{input: :path} = options
       ) do
    function_return = function.(value)
    resolve_function_return(result, function, function_return, options)
  end

  defp resolve_direct_value(%Result{tag: tag}, direct_value, %Options{name: name} = options) do
    %Result{tag: tag, name: name, value: direct_value}
  end

  defp resolve_function_return(%Result{tag: tag}, function, function_return, %Options{name: name} = options) do
    {new_tag, new_value} =
      case options.bare do
        true -> {:ok, function_return}
        false ->
          case function_return do
            {:ok, _value} -> function_return
            {:error, _value} -> function_return
            _ -> raise("Return value for function #{inspect(function)} via name #{inspect(name)} must be of the form {:ok | :error, any()}.")
          end
      end

    final_tag = resolve_tag(tag, new_tag, options.control)
    %Result{tag: final_tag, name: name, value: new_value}
  end

  defp resolve_tag(old_tag, new_tag, control) do
    case control do
      :attempt ->
        case new_tag do
          :error -> :error
          :ok -> old_tag
        end

      :hold ->
        old_tag

      :recover ->
        new_tag
    end
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

  defp add_to_path(%Path{} = path, tag, value) when tag == :ok or tag == :error do
    new_result = %Result{tag: tag, value: value}
    %Path{result: new_result, history: [new_result | path.history]}
  end

  defp add_to_path(%Path{} = path, value) do
    new_result = %Result{tag: path.result.tag, value: value}
    %Path{result: new_result, history: [new_result | path.history]}
  end

  def do_memorize_many(path, [{k, v} | values]) do
    resolve_path(path, v, name: k, return: :memorize, path: :both)
    |> do_memorize_many(values)
  end

  @doc false
  def do_memorize_many(path, []) do
    path
  end

end
