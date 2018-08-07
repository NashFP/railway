defmodule OwlBear do
  @moduledoc """
  OwlBear handles both the happy paths and the error paths of functions within a single Elixir pipeline.

  But the poor OwlBear is a terribly conflicted creature, light and free like an `{:ok, owl}`, heavy and brutal
  like an angry `{:error, bear}`.

  ### Run
  _...to run functions on the happy path..._

  Functions are generally expected to return tuples such as `{:ok, value}` or `{error, value}`.

  Functions ending with a bang (`!`) assume success with an unwrapped return value.

  Normally, the OwlBear just runs along. A result tuple is released when the OwlBears decides to `rest`.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run!(fn msg -> msg <> ", let's be friends!" end)
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
      ...> |> eat(fn _ -> {:ok, "Not dead yet?"} end)
      ...> |> eat(fn _ -> {:error, "Run away! Run away!"} end)
      ...> |> eat(fn _ -> {:ok, "Are we safe now?"} end)
      ...> |> rest()
      {:error, "Are we safe now?"}

  When OwlBear eats something, he will always pass along the value, but cannot
  recover from the error path.


  ### Attack
  _...to overcome the errors in our way..._

  OwlBear can find his way back to the happy path, by taking errors down (attacking the problem).

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> eat(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> eat(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> attack(fn _ -> {:ok, "Adventurer parts are everywhere."} end)
      ...> |> attack(fn _ -> {:ok, "This might be overkill."} end)
      ...> |> attack(fn _ -> {:ok, "I think we got him."} end)
      ...> |> rest()
      {:ok, "Adventurer parts are everywhere."}

  Attacks are only executed when on the `:error` path. A successful attack will bring OwlBear back to the `:ok` world.


  """

  require Logger
  alias OwlBear.{Path, Result, Options, History}

  @type tag_result :: {:ok | :error, any()}
  @type name :: atom() | nil
  @type memories :: [atom()]

  @doc """
  Operates only on the `:ok` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:error` tuple is returned, the path will shift to the `:error` state.

  ## Examples
      iex> {:ok, 10} |> OwlBear.run(fn x -> {:ok, x * 2} end) |> OwlBear.rest()
      {:ok, 20}
      iex> {:ok, 10} |> OwlBear.run(fn x -> {:error, x * 5} end) |> OwlBear.rest()
      {:error, 50}
      iex> {:error, 7} |> OwlBear.run(fn x -> {:ok, x * 3} end) |> OwlBear.rest()
      {:error, 7}
  """

  @spec run(any(), function(), name()) :: Path.t()
  def run(path, function, name \\ nil) do
    resolve_path(path, function, name: name)
  end

  @doc """
  Operates only on the `:ok` path and assumes success.
  Calls the function `fn/1 :: any()` with the current path value.

  ## Examples
      iex> {:ok, 4} |> OwlBear.run!(fn x -> x * 3 end) |> OwlBear.rest()
      {:ok, 12}
      iex> {:error, 1} |> OwlBear.run!(fn x -> x * 5 end) |> OwlBear.rest()
      {:error, 1}
  """

  @spec run!(any(), function(), name()) :: Path.t()
  def run!(path, function, name \\ nil) do
    resolve_path(path, function, name: name, bang: true)
  end

  @doc """
  Operates only on the `:error` path.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current path value.
  If an `:ok` tuple is returned, the path will recover to the `:ok` state.

  ## Examples
      iex> {:error, 3} |> OwlBear.attack(fn x -> {:ok, x * 2} end) |> OwlBear.rest()
      {:ok, 6}
      iex> {:ok, 4} |> OwlBear.attack(fn x -> {:ok, x * 5} end) |> OwlBear.rest()
      {:ok, 4}
      iex> {:error, 7} |> OwlBear.attack(fn x -> {:error, x + 3} end) |> OwlBear.rest()
      {:error, 10}
  """

  @spec attack(any(), function(), name()) :: Path.t()
  def attack(path, function, name \\ nil) do
    resolve_path(path, function, name: name, path: :error, control: :recover)
  end

  @doc """
  Operates only on the `:error` path and assumes success, returning to the :ok path.
  Calls the function `fn/1 :: any()` with the current path value.

  ## Examples
      iex> {:error, 12} |> OwlBear.attack!(fn x -> x * 3 end) |> OwlBear.rest()
      {:ok, 36}
      iex> {:ok, 7} |> OwlBear.attack!(fn x -> x * 5 end) |> OwlBear.rest()
      {:ok, 7}
  """

  @spec attack!(any(), function(), name()) :: Path.t()
  def attack!(path, function, name \\ nil) do
    resolve_path(path, function, name: name, bang: true, path: :error, control: :recover)
  end

  @spec attack_history(any(), function(), name()) :: Path.t()
  def attack_history(path, function, name \\ nil) do
    resolve_path(
      path,
      function,
      name: name,
      bang: true,
      path: :error,
      control: :recover,
      return: :history
    )
  end

  @spec eat(any(), function(), name()) :: Path.t()
  def eat(path, function, name \\ nil) do
    resolve_path(path, function, name: name, path: :both)
  end

  @spec eat!(any(), function(), name()) :: Path.t()
  def eat!(path, function, name \\ nil) do
    resolve_path(path, function, name: name, path: :both, bang: true)
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the current `:ok` path value.

  The return value is ignored and the path will remain unchanged.

  ## Examples
      iex> {:ok, "low"} |> OwlBear.hoot(fn x -> IO.puts("danger " <> x) end) |> OwlBear.rest()
      {:ok, "low"}
      iex> {:error, "high"} |> OwlBear.hoot(fn x -> IO.puts("danger " <> x) end) |> OwlBear.rest()
      {:error, "high"}

  Note that "danger low" would appear in the actual output for the 1st example.
  """

  @spec hoot(any(), function()) :: Path.t()
  def hoot(path, function) do
    resolve_path(path, function, return: :noop, bang: true)
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the path history if on the `:ok` path.

  The return value is ignored and the path will remain unchanged.
  """

  @spec hoot_history(any(), function()) :: Path.t()
  def hoot_history(path, function) do
    resolve_path(path, function, return: :noop, bang: true, return: :history)
  end

  @spec talk(any(), function()) :: Path.t()
  def talk(path, function) do
    resolve_path(path, function, return: :noop, bang: true, path: :both)
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the path history from either path.

  The return value is ignored and the path will remain unchanged.
  """

  @spec talk_history(any(), function()) :: Path.t()
  def talk_history(path, function) do
    resolve_path(path, function, return: :noop, bang: true, path: :both, return: :history)
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the current `:error` path value.

  The return value is ignored and the path will remain unchanged.

  ## Examples
      iex> {:ok, "low"} |> OwlBear.growl(fn x -> IO.puts("danger " <> x) end) |> OwlBear.rest()
      {:ok, "low"}
      iex> {:error, "high"} |> OwlBear.growl(fn x -> IO.puts("danger " <> x) end) |> OwlBear.rest()
      {:error, "high"}

  Note that "danger high" would appear in the actual output for the 2nd example.
  """

  @spec growl(any(), function()) :: Path.t()
  def growl(path, function) do
    resolve_path(path, function, return: :noop, bang: true, path: :error)
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the path history if on the `:error` path.

  The return value is ignored and the path will remain unchanged.
  """

  @spec growl_history(Path.t(), function()) :: Path.t()
  def growl_history(path, function) do
    resolve_path(path, function, return: :noop, bang: true, path: :error, return: :history)
  end

  @spec jump(any(), function(), name()) :: Path.t()
  def jump(path, function, name \\ nil) do
    resolve_path(path, function, name: name, try: true)
  end

  @spec jump!(any(), function(), name()) :: Path.t()
  def jump!(path, function, name \\ nil) do
    resolve_path(path, function, name: name, bang: true, try: true)
  end

  @spec run_using(any(), function(), memories(), name()) :: Path.t()
  def run_using(path, function, memories, name \\ nil) do
    recall_memories(path, memories)
    |> resolve_path(function, name: name, input: :memories)
  end

  @spec run_using!(any(), function(), memories(), name()) :: Path.t()
  def run_using!(path, function, memories, name \\ nil) do
    recall_memories(path, memories)
    |> resolve_path(function, name: name, input: :memories, bang: true)
  end

  @spec jump_using(any(), function(), memories(), name()) :: Path.t()
  def jump_using(path, function, memories, name \\ nil) do
    recall_memories(path, memories)
    |> resolve_path(function, name: name, try: true, input: :memories)
  end

  @spec jump_using!(any(), function(), memories(), name()) :: Path.t()
  def jump_using!(path, function, memories, name \\ nil) do
    recall_memories(path, memories)
    |> resolve_path(function, name: name, bang: true, try: true, input: :memories)
  end

  @spec memorize(any(), atom(), any()) :: Path.t()
  def memorize(path, name, value) do
    resolve_path(path, value, name: name, return: :memorize)
  end

  @spec memorize_many(any(), keyword()) :: Path.t()
  def memorize_many(path, [{k, v} | values]) do
    resolve_path(path, v, name: k, return: :memorize)
    |> memorize_many(values)
  end

  @spec memorize_many(any(), []) :: Path.t()
  def memorize_many(path, []) do
    path
  end

  @spec recall_memories(any(), memories(), name()) :: Path.t()
  def recall_memories(path, memories, name \\ nil) do
    memorize(path, name, extract_ok_values(path, memories))
  end

  @spec rest(Path.t()) :: tag_result()
  def rest(%Path{} = path) do
    {path.result.tag, path.result.value}
  end

  # internal

  defp extract_ok_values(path, memory_names) do
    extract_results(path, memory_names)
    |> Enum.map(&Result.result_to_ok_value/1)
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
          %Result{path.result | skip: true, name: nil}

        :function ->
          resolve_function(path.result, function, options)

        :noop ->
          resolve_function(path.result, function, options)
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

  defp resolve_function_input(%Result{} = result, function, %Options{input: :off_path} = options) do
    function_return = function.()
    resolve_function_return(result, function, function_return, options)
  end

  defp resolve_direct_value(%Result{tag: tag}, direct_value, %Options{name: name} = options) do
    %Result{tag: tag, name: name, value: direct_value}
  end

  defp resolve_function_return(%Result{tag: tag}, function, function_return, %Options{name: name} = options) do
    {new_tag, new_value} =
      case options.bang do
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

  def moo(x) do
     x <> "cow"
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
end
