defmodule TTTest do

  use ExUnit.Case
  doctest TT
  require Logger

  def add_two_numbers(x) when is_integer(x) do
      fn y when is_integer(y) -> x + y end
  end

  def add_two_strings(x) when is_binary(x) do
      fn y when is_binary(y) -> x <> y end
  end

  def crashy_uppercase(message) when is_binary(message) do
    raise "argh " <> message
  end

  def rop_divide(x) when is_integer(x) do
    fn y ->
      case x do
        0 -> {:error, :division_by_zero}
        _ -> {:ok, y / x}
      end
    end
  end

  test "successful run! with normal function" do

    result =
      5
      |> TT.run!(add_two_numbers(2))
      |> TT.eol

    assert {:ok, 7} == result
  end

  test "successful run with tagging function" do

    result =
      10
      |> TT.run(rop_divide(5))
      |> TT.eol

    assert {:ok, 2} == result
  end

  test "failing run with tagging function" do

    result =
      10
      |> TT.run(rop_divide(0))
      |> TT.eol

    assert {:error, :division_by_zero} == result
  end

  test "failing try with normal function" do

    result =
      "train"
      |> TT.try!(&crashy_uppercase/1)
      |> TT.eol

    assert {:error, %RuntimeError{message: "argh train"}} == result
  end

  test "successful chain" do

    result =
      5
      |> TT.run!(add_two_numbers(2))
      |> TT.run(rop_divide(10))
      |> TT.eol

    assert {:ok, 0.7} == result
  end

end
