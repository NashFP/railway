defmodule OwlBearTest do
  use ExUnit.Case
  doctest OwlBear

  require Logger
  #  import OwlBear, only: [>>>: 2]

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

  test "successful fly! with normal function" do
    import OwlBear

    result =
      {:ok, 5}
      #      |> OwlBear.cache(:cow, 6)
      #      |> OwlBear.cache(:dog, 0)
      |> memorize_many(dog: 0, cow: 6)
      #      |> OwlBear.try(fn _ -> crashy_uppercase("moo!") end)
      |> run!(fn x -> add_two_numbers(x, 9) end)
      |> hoot(fn x -> Logger.warn("signal be #{inspect(x)}") end)
      |> run_using(&rop_divide/2, [:cow, :dog], :cat)
      |> growl_history(fn h -> IO.puts(inspect(h)) end)
      #      |> OwlBear.cache!(:moo, 11)
      |> rest()

    #      >>> add_two_numbers(2,9), name: :moo, return: :value
    assert {:ok, 3.0} == result
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
