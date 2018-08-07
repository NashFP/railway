defmodule OwlBear.History do
  alias OwlBear.{History, Result}

  @type t :: [Result.t()]

  @spec to_named_oks(History.t()) :: keyword()
  def to_named_oks(history) do
    history
    |> Enum.filter(fn r -> r.skip == false and r.tag == :ok and r.name != nil end)
    |> Enum.uniq_by(fn r -> r.name end)
    |> Enum.map(fn r -> {r.name, r.value} end)
  end

  @spec to_named_errors(History.t()) :: keyword()
  def to_named_errors(history) do
    history
    |> Enum.filter(fn r -> r.skip == false and r.tag == :error and r.name != nil end)
    |> Enum.uniq_by(fn r -> r.name end)
    |> Enum.map(fn r -> {r.name, r.value} end)
  end
end
