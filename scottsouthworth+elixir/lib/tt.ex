defmodule TT do
  @moduledoc false

  @type tagged_result :: {:ok | :error, any()}
  @type track_result :: {:ok | :error, any(), [tagged_result]}

  @spec try(tagged_result() | track_result(), function()) :: track_result()

  def try({:ok, value}, function) when is_function(function) do
    try({:ok, value, []}, function)
  end

  def try({:error, value}, function) when is_function(function) do
    {:error, value, []}
  end

  def try({:error, _value, history} = current_track, function)
      when is_function(function) and is_list(history) do
    current_track
  end

  def try({:ok, value, history}, function) when is_function(function) and is_list(history) do

    try do
      function.(value)
    rescue
      e in RuntimeError -> {:error, e}
    end
    |>
    case do
      {:ok, new_value} = result -> {:ok, new_value, [result | history]}
      {:error, new_value} = result -> {:error, new_value, [result | history]}
      result -> {:error, result, [{:error, result} | history]}
    end

  end

  @spec try!(tagged_result() | track_result(), function()) :: track_result()

  def try!({:ok, value}, function) when is_function(function) do
    try!({:ok, value, []}, function)
  end

  def try!({:error, value}, function) when is_function(function) do
    {:error, value, []}
  end

  def try!({:ok, value, history}, function) when is_list(history) and is_function(function) do
    try do
      {:ok, function.(value)}
    rescue
      e in RuntimeError -> {:error, e}
    end
    |>
    case do
      {:ok, new_value} = result -> {:ok, new_value, [result | history]}
      {:error, new_value} = result -> {:error, new_value, [result | history]}
    end
  end

  def try!({:error, _value, history} = current_track, function)
      when is_function(function) and is_list(history) do
    current_track
  end

  def try!(value, function) when is_function(function) do
    try!({:ok, value, []}, function)
  end

  @spec run(tagged_result() | track_result(), function()) :: track_result()

  def run({:ok, value}, function) when is_function(function) do
    run({:ok, value, []}, function)
  end

  def run({:error, value}, function) when is_function(function) do
    {:error, value, []}
  end

  def run({:ok, value, history}, function) when is_function(function) and is_list(history) do
    result = function.(value)

    case result do
      {:ok, new_value} -> {:ok, new_value, [result | history]}
      {:error, new_value} -> {:error, new_value, [result | history]}
      _ -> {:error, result, [{:error, result} | history]}
    end
  end

  def run({:error, _value, history} = current_track, function)
      when is_function(function) and is_list(history) do
    current_track
  end

  def run(value, function) when is_function(function) do
    result = function.(value)

    case result do
      {:ok, new_value} -> {:ok, new_value, [result]}
      {:error, new_value} -> {:error, new_value, [result]}
      _ -> {:error, result, [{:error, result}]}
    end
  end

  @spec run!(tagged_result() | track_result(), function()) :: track_result()

  def run!({:ok, value}, function) when is_function(function) do
    run!({:ok, value, []}, function)
  end

  def run!({:error, value}, function) when is_function(function) do
    {:error, value, []}
  end

  def run!({:ok, value, history}, function) when is_list(history) and is_function(function) do
    new_value = function.(value)
    result = {:ok, new_value}
    {:ok, new_value, [result | history]}
  end

  def run!({:error, _value, history} = current_track, function)
      when is_list(history) and is_function(function) do
    current_track
  end

  def run!(value, function) when is_function(function) do
    run!({:ok, value, []}, function)
  end

  @spec unload(tagged_result() | track_result()) :: track_result()

  def unload({tag, value}) do
    unload({tag, value, []})
  end

  def unload({:ok, value, history} = current_track) when is_list(history) do
    case value do
      _ when is_list(value) ->
        ok_entries =
          value
          |> Enum.filter(fn
            {:ok, _} -> true
            _ -> false
          end)
          |> Enum.map(fn {:ok, v} -> v end)

        {:ok, ok_entries, [{:ok, ok_entries} | history]}

      {:ok, v} ->
        {:ok, v, [{:ok, v} | history]}

      _ ->
        current_track
    end
  end

  @spec check(tagged_result() | track_result(), function()) :: track_result()

  def check({tag, value}, function) when is_function(function) do
    check({tag, value, []}, function)
  end

  def check({tag, value, history}, function) when is_list(history) and is_function(function) do
    result = function.(value)

    case {tag, result} do
      {:ok, {:ok, _new_value}} -> {:ok, value, [result | history]}
      {:error, {new_tag, new_value}} -> {:error, value, [{new_tag, new_value} | history]}
      _ -> {:error, value, [{:error, result} | history]}
    end
  end

  @spec spur(tagged_result() | track_result(), function()) :: track_result()

  def spur({tag, value}, function) when is_function(function) do
    spur({tag, value, []}, function)
  end

  def spur({tag, value, history} = current_track, function)
      when is_list(history) and is_function(function) do
    case tag do
      :ok -> function.(value)
      _ -> :noop
    end

    current_track
  end

  @spec manage(tagged_result() | track_result(), function()) :: track_result()

  def manage({tag, value}, function) when is_function(function) do
    spur({tag, value, []}, function)
  end

  def manage({tag, _value, history} = current_track, function)
      when is_atom(tag) and is_list(history) and is_function(function) do
    result = function.(current_track)

    case result do
      {:ok, new_value} ->
        {:ok, new_value, [{:ok, new_value} | history]}

      {:error, new_value} ->
        {:error, new_value, [{:error, new_value} | history]}

      {:ok, new_value, more_history} when is_list(more_history) ->
        {:ok, new_value, [[{:ok, new_value} | more_history] | history]}

      {:error, new_value, more_history}  when is_list(more_history) ->
        {:error, new_value, [[{:error, new_value} | more_history] | history]}

      _ ->
        {:error, result, [{:error, result} | history]}
    end

    current_track
  end

  @spec report(tagged_result() | track_result(), function()) :: track_result()

  def report({tag, value}, function) when is_function(function) do
    report({tag, value, []}, function)
  end

  def report({:ok, _value, history} = current_track, function)
      when is_list(history) and is_function(function) do
    function.(current_track)
    current_track
  end

  def report({:error, _value, history} = current_track, function)
      when is_list(history) and is_function(function) do
    function.(current_track)
    current_track
  end

  @spec eol(track_result()) :: tagged_result()
  @spec eol(track_result(), function()) :: tagged_result()

  def eol({tag, value, history}) when is_list(history) do
    {tag, value}
  end

  def eol({tag, _value, history} = current_track, function)
      when is_atom(tag) and is_list(history) and is_function(function) do
    {new_tag, new_value, _new_history} = manage(current_track, function)
    {new_tag, new_value}
  end

end
