defmodule TTTest do
  use ExUnit.Case
  doctest TT
  require Logger
  import TT, only: [>>>: 2]

  def add_two_numbers(x, y) do
   Logger.warn("adding two: #{inspect(x)} and #{inspect(y)}")
   x + y
  end

  def add_two_strings(x, y) do
    x <> y
  end

  def crashy_uppercase(message) when is_binary(message) do
    raise "CrAsH! " <> message
  end

  def rop_divide(x, y) do

      case y do
        0 -> {:error, :division_by_zero}
        _ -> {:ok, x / y}
      end

  end

  test "successful run! with normal function" do
    result =
      {:ok, 5}
      |> TT.run!(fn x -> add_two_numbers(x, 9) end)
#      |> TT.cache!(:moo, 11)
      |> TT.eol()
#      >>> add_two_numbers(2,9), name: :moo, return: :value
    assert {:ok, 14} == result
  end

#  test "successful run with tagging function" do
#    result =
#      10
#      |> TT.run(rop_divide(5,3), :cow)
#      |> TT.value(:cow)
#      |> TT.warn()
#      |> TT.eol()
#
#    assert {:ok, 2} == result
#  end
#
#  test "failing run with tagging function" do
#    result =
#      10
#      |> TT.run(rop_divide(0), :div)
#      |> TT.eol()
#
#    assert {:error, :division_by_zero} == result
#  end
#
#  test "failing try with normal function" do
#    result =
#      "train"
#      |> TT.attempt!(&crashy_uppercase/1)
#      |> TT.eol()
#
#    assert {:error, %RuntimeError{message: "argh train"}} == result
#  end
#
#  test "successful chain" do
#    result =
#      5
#      |> TT.run!(add_two_numbers(2), :cow)
#      |> TT.run(rop_divide(10), :moo)
#      |> TT.values([:cow, :moo])
#      |> TT.run!(&add_numbers/2)
#
#    Logger.warn("grrr" <> inspect(result))
#    #      >>> rop_divide(10)
#    result =
#      result
#      |> TT.eol()
#
#    assert {:ok, 0.7} == result
#  end
end
