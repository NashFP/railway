defmodule OwlBearTest do
  use ExUnit.Case
  doctest OwlBear
  doctest OwlBear.DOP

  require Logger

  def add_two_numbers(x, y) do
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

  test "successful! with normal function" do
    import OwlBear

    result =
      board(cow: 6, dog: 0, nil: 5)
      #      |> OwlBear.cache(:cow, 6)
      #      |> OwlBear.cache(:dog, 0)
      #      |> note(dog: 0, cow: 6)
      #      |> OwlBear.try(fn _ -> crashy_uppercase("moo!") end)
      |> run(fn x -> add_two_numbers(x, 9) end, wrap: true)
      |> note(fn x -> Logger.warn("signal be #{inspect(x)}") end, wrap: true)
      |> run(fn m -> rop_divide(m.cow, m.dog) end, name: :cat, map: :ok)
      #      |> signal_history(fn h -> IO.puts(inspect(h)) end)
      #      |> OwlBear.cache!(:moo, 11)
      |> eol()

    #      >>> add_two_numbers(2,9), name: :moo, return: :value
    assert {:error, :division_by_zero} == result
  end

  #  test "successful fly with tagging function" do
  #    result =
  #      10
  #      |> OwlBear.fly(rop_divide(5,3), :cow)
  #      |> OwlBear.value(:cow)
  #      |> OwlBear.warn()
  #      |> OwlBear.eol()
  #
  #    assert {:ok, 2} == result
  #  end
  #
  #  test "failing fly with tagging function" do
  #    result =
  #      10
  #      |> OwlBear.fly(rop_divide(0), :div)
  #      |> OwlBear.eol()
  #
  #    assert {:error, :division_by_zero} == result
  #  end
  #
  #  test "failing try with normal function" do
  #    result =
  #      "train"
  #      |> OwlBear.aowlBearempt!(&crashy_uppercase/1)
  #      |> OwlBear.eol()
  #
  #    assert {:error, %FlytimeError{message: "argh train"}} == result
  #  end
  #
  #  test "successful chain" do
  #    result =
  #      5
  #      |> OwlBear.fly!(add_two_numbers(2), :cow)
  #      |> OwlBear.fly(rop_divide(10), :moo)
  #      |> OwlBear.values([:cow, :moo])
  #      |> OwlBear.fly!(&add_numbers/2)
  #
  #    Logger.warn("grrr" <> inspect(result))
  #    #      >>> rop_divide(10)
  #    result =
  #      result
  #      |> OwlBear.eol()
  #
  #    assert {:ok, 0.7} == result
  #  end
end
