defmodule OwlBear.Result do
  alias OwlBear.Result

  @moduledoc false

  defstruct tag: :ok, name: nil, value: nil, skip: false
  @type tag :: :ok | :error
  @type t :: %OwlBear.Result{
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
      %Result{tag: :ok, value: v, skip: false} ->
        v

      _ when is_list(value) ->
        list_entries =
          case Keyword.keyword?(value) do
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

      {:ok, v} ->
        v

      _ ->
        value
    end
  end
end
