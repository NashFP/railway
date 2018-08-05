
defmodule TT.Result do

  @moduledoc false

  alias TT.Result
  defstruct tag: :ok, name: nil, value: nil, skip: false
  @type tag :: :ok | :error
  @type t :: %TT.Result{
                tag: tag(),
                name: atom() | nil,
                value: any(),
                skip: boolean
             }

  def result_to_ok_value(%Result{} = result) do
    {:ok, value} = {result.tag, result.value}
    value
  end

  def result_to_error_value(%Result{} = result) do
    {:error, value} = {result.tag, result.value}
    value
  end
  
  def tag_error(value) do
    {:error, value}
  end

  def tag_ok(value) do
    {:ok, value}
  end

  def unload_inside({:ok, value}) do
    {:ok, unload(value)}
  end

  def unload_inside(%Result{tag: :ok, value: value, skip: false}) do
    {:ok, unload(value)}
  end

  def unload(value) do

    case value do

      %Result{tag: :ok, value: v, skip: false} -> v

      _ when is_list(value) ->

        list_entries = case Keyword.keyword?(value) do
          true -> Keyword.values(value)
          false -> value
        end

        list_entries
        |> Enum.filter(fn
          {:ok, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:ok, v} -> v end)

      _ when is_map(value) ->

        value
        |> Enum.to_list()
        |> Enum.filter(fn
          {:ok, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:ok, v} -> v end)

      {:ok, v} -> v

      _ ->
        value

    end
  end

end


defmodule TT.Options do

  @moduledoc false

  defstruct name: nil, input: :railway, try: false, bang: false, track: :ok, control: :derail, return: :function

  @type return_options :: :noop | :history | :function | :cache
  @type control_options :: :hold | :veer | :derail
  @type track_options :: :ok | :error | :both
  @type input_options :: :railway | :tickets | :off_track

  @type t :: %TT.Options{
               name: atom | nil,
               try: boolean,
               bang: boolean,
               input: input_options(),
               return: return_options(),
               track: track_options(),
               control: control_options()
             }

  # options:
  #          :try    - rescue to :error tuple
  #          :bang   - need to wrap function return in :ok tuple
  #          :track   - function runs on :ok, :error or :both tracks
  #          :return  - how is the value stored and returned
  #                :noop  - nothing stored, track value unchanged
  #                :history - history of track returned
  #                :cache - value stored in history and returned
  #                :lookup - value(s) pulled from history and returned
  #                :function - default, runs function and returns value
  #          :control    - controls the track we are on
  #               :hold    - tag does not change based on result
  #               :veer   - tag becomes the latest result (even to recover)
  #               :derail  - tag can become error (default)
  #          :input      - what gets passed in to function?
  #               :railway - current value on the track
  #               :tickets   - current value used as kernel.apply (must be array)
  #               :off_track - function called as arity 0 (ignores current track value)
  #

  # check = track: both, control: derail
end

defmodule TT.Track do
  @moduledoc false

  defstruct result: %TT.Result{}, history: []
  @type t :: %TT.Track{
               result:  TT.Result.t(),
               history: [TT.Result.t()],
             }
end


defmodule TT do

  require Logger
  alias TT.{Track, Result, Options}

  @type tag_result :: {:ok | :error, any()}
  @type name :: atom() | nil
  @type tickets :: [atom()]

  @doc """
  Operates on the `:ok` track.
  Calls the function `fn/1 :: {:ok | :error, any()}` with the current track value.
  If an `:error` tuple is returned, the track will shift to the `:error` state.

  ## Examples
      iex> {:ok, 10} |> TT.run(fn x -> {:ok, x * 2} end) |> TT.eol()
      {:ok, 20}
      iex> {:ok, 10} |> TT.run(fn x -> {:error, x * 5} end) |> TT.eol()
      {:error, 50}
      iex> {:error, 7} |> TT.run(fn x -> {:ok, x * 3} end) |> TT.eol()
      {:error, 7}
  """

  @spec run(any(), function(), name()) :: Track.t()
  def run(track, function, name \\ nil) do
    resolve_track(track, function, [name: name])
  end

  @doc """
  Operates on the `:ok` track.
  Calls the function `fn/1 :: any()` with the current track value.
  If an `:error` tuple is returned, the track will shift to the `:error` state.

  ## Examples
      iex> {:ok, 4} |> TT.run!(fn x -> x * 3 end) |> TT.eol()
      {:ok, 12}
      iex> {:ok, 17} |> TT.run(fn x -> {:error, x + 5} end) |> TT.eol()
      {:error, 22}
      iex> {:error, 1} |> TT.run!(fn x -> x * 5 end) |> TT.eol()
      {:error, 1}
  """

  @spec run!(any(), function(), name()) :: Track.t()
  def run!(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, bang: true])
  end

  @spec veer(any(), function(), name()) :: Track.t()
  def veer(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, track: :both, control: :veer])
  end

  @spec veer!(any(), function(), name()) :: Track.t()
  def veer!(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, bang: true, track: :both, control: :veer])
  end

  @spec veer_history(any(), function(), name()) :: Track.t()
  def veer_history(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, bang: true, track: :both, control: :veer, return: :history])
  end

  @spec check(any(), function(), name()) :: Track.t()
  def check(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, track: :both])
  end

  @spec check!(any(), function(), name()) :: Track.t()
  def check!(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, track: :both, bang: true])
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the current `:ok` track value.

  The return value is ignored and the track will remain unchanged.

  ## Examples
      iex> {:ok, "low"} |> TT.hoot_success(fn x -> IO.puts("danger " <> x) end) |> TT.eol()
      {:ok, "low"}
      iex> {:error, "high"} |> TT.hoot_success(fn x -> IO.puts("danger " <> x) end) |> TT.eol()
      {:error, "high"}

  Note that "danger low" would appear in the actual output for the 1st example.
  """

  @spec hoot_success(any(), function()) :: Track.t()
  def hoot_success(track, function) do
    resolve_track(track, function, [return: :noop, bang: true])
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the track history if on the `:ok` track.

  The return value is ignored and the track will remain unchanged.
  """

  @spec hoot_history(any(), function()) :: Track.t()
  def hoot_history(track, function) do
    resolve_track(track, function, [return: :noop, bang: true, return: :history])
  end

  @spec peek(any(), function()) :: Track.t()
  def peek(track, function) do
    resolve_track(track, function, [return: :noop, bang: true, track: :both])
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the track history from either track.

  The return value is ignored and the track will remain unchanged.
  """

  @spec peek_history(any(), function()) :: Track.t()
  def peek_history(track, function) do
    resolve_track(track, function, [return: :noop, bang: true, track: :both, return: :history])
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the current `:error` track value.

  The return value is ignored and the track will remain unchanged.

  ## Examples
      iex> {:ok, "low"} |> TT.growl_error(fn x -> IO.puts("danger " <> x) end) |> TT.eol()
      {:ok, "low"}
      iex> {:error, "high"} |> TT.growl_error(fn x -> IO.puts("danger " <> x) end) |> TT.eol()
      {:error, "high"}

  Note that "danger high" would appear in the actual output for the 2nd example.
  """

  @spec growl_error(any(), function()) :: Track.t()
  def growl_error(track, function) do
    resolve_track(track, function, [return: :noop, bang: true, track: :error])
  end

  @doc """
  Calls the function `fn/1 :: any()` as a side-effect with the track history if on the `:error` track.

  The return value is ignored and the track will remain unchanged.
  """

  @spec growl_history(Track.t(), function()) :: Track.t()
  def growl_history(track, function) do
    resolve_track(track, function, [return: :noop, bang: true, track: :error, return: :history])
  end

  @spec try_catch(any(), function(), name()) :: Track.t()
  def try_catch(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, try: true])
  end

  @spec try_catch!(any(), function(), name()) :: Track.t()
  def try_catch!(track, function, name \\ nil) do
    resolve_track(track, function, [name: name, bang: true, try: true])
  end

  @spec run_tickets(any(), function(), tickets(), name()) :: Track.t()
  def run_tickets(track, function, tickets, name \\ nil) do
    cache_tickets(track, tickets)
    |> resolve_track(function, [name: name, input: :tickets])
  end

  @spec run_tickets!(any(), function(), tickets(), name()) :: Track.t()
  def run_tickets!(track, function, tickets, name \\ nil) do
    cache_tickets(track, tickets)
    |> resolve_track(function, [name: name, input: :tickets, bang: true])
  end

  @spec try_catch_tickets(any(), function(), tickets(), name()) :: Track.t()
  def try_catch_tickets(track, function, tickets, name \\ nil) do
    cache_tickets(track, tickets)
    |> resolve_track(function, [name: name, try: true, input: :tickets])
  end

  @spec try_catch_tickets!(any(), function(), tickets(), name()) :: Track.t()
  def try_catch_tickets!(track, function, tickets, name \\ nil) do
    cache_tickets(track, tickets)
    |> resolve_track(function, [name: name, bang: true, try: true, input: :tickets])
  end

  @spec cache(any(), atom(), any()) :: Track.t()
  def cache(track, name, value) do
    resolve_track(track, value, [name: name, return: :cache])
  end

  @spec cache_many(any(), keyword()) :: Track.t()
  def cache_many(track, [{k, v} | values]) do
    resolve_track(track, v, [name: k, return: :cache])
    |> cache_many(values)
  end

  @spec cache_many(any(), []) :: Track.t()
  def cache_many(track, []) do
    track
  end

  @spec cache_tickets(any(), tickets(), name()) :: Track.t()
  def cache_tickets(track, tickets, name \\ nil) do
    cache(track, name, extract_ok_values(track, tickets))
  end

  @spec eol(Track.t()) :: tag_result()
  def eol(%Track{} = track) do
    {track.result.tag, track.result.value}
  end

  # internal

  defp extract_ok_values(track, arg_names) do
    extract_results(track, arg_names)
    |> Enum.map(&TT.Result.result_to_ok_value/1)
  end

  defp extract_results(track, arg_names) do
    tagged_values = Enum.map(arg_names,
      fn name ->
        Enum.find(track.history, {:error, :ticket_not_found}, fn r -> r.name == name and r.skip == false end)
      end)
  end

  defp resolve_track(track_or_value, function, options_or_keywords) do

    track = to_track(track_or_value)
    options = to_options(options_or_keywords)
    on_track = is_on_track?(track.result, options)

    case on_track do
      true -> resolve_on_track(track, function, options)
      false -> resolve_off_track(track, function, options)
    end

  end

  defp resolve_on_track(%Track{} = track, function, %Options{} = options) do

    new_result = case options.return do
      :history ->
        history_result = %Result{ track.result | value: track.history, name: nil}
        resolve_function(history_result, function, options)
      :function -> resolve_function(track.result, function, options)
      :noop -> resolve_function(track.result, function, options)
               %Result{track.result | skip: true, name: nil}
      :cache -> resolve_direct_value(track.result, function, options)
    end

    new_history = [new_result | track.history]
    %Track{result: new_result, history: new_history}

  end

  defp resolve_off_track(%Track{} = track, _function, %Options{} = options) do

    skip_result = %Result{ track.result | skip: true, name: options.name}
    new_history = [skip_result | track.history]
    %Track{result: track.result, history: new_history}

  end

  defp is_on_track?(%Result{tag: tag}, %Options{track: track}) do
    case {tag, track} do
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

  defp resolve_function(%Result{} = result, function, %Options{try: false} = options)  do
    resolve_function_input(result, function, options)
  end

  defp resolve_function_input(%Result{value: value} = result, function, %Options{name: name, input: :tickets} = options) do
    case is_list(value) do
      true -> function_return = apply(function, value)
              resolve_function_return(result, function_return, options)
      false ->
        Logger.warn("got #{inspect(value)}")
        %Result{tag: :error, name: name, value: :cannot_apply_non_list_value}
    end
  end

  defp resolve_function_input(%Result{value: value} = result, function, %Options{input: :railway} = options) do

    function_return = function.(value)
    resolve_function_return(result, function_return, options)

  end

  defp resolve_function_input(%Result{} = result, function, %Options{input: :off_track} = options) do

    function_return = function.()
    resolve_function_return(result, function_return, options)

  end

  defp resolve_direct_value(%Result{tag: tag}, direct_value, %Options{name: name} = options) do
    %Result{tag: tag, name: name, value: direct_value}
  end

  defp resolve_function_return(%Result{tag: tag}, function_return, %Options{name: name} = options) do

    {new_tag, new_value} =
      case options.bang do
        true -> {:ok, function_return}
        false -> function_return
      end

    final_tag = resolve_tag(tag, new_tag, options.control)
    %Result{tag: final_tag, name: name, value: new_value}

  end

  defp resolve_tag(old_tag, new_tag, control) do
    case control do
      :derail ->
        case new_tag do
          :error -> :error
          :ok -> old_tag
        end
      :hold -> old_tag
      :veer -> new_tag
    end
  end

  defp to_options(%Options{} = options) do
    options
  end

  defp to_options(list) when is_list(list) do
    true = Keyword.keyword?(list)
    Enum.reduce(list, %Options{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp to_track(%Track{} = track) do
    track
  end

  defp to_track({tag, value}) when tag == :ok or tag == :error do
    %Track{result: %Result{tag: tag, value: value}}
  end

  defp to_track(value) do
    %Track{result: %Result{tag: :ok, value: value}}
  end


end
