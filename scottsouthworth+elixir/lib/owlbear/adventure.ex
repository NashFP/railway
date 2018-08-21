defmodule OwlBear.Adventure do
  alias OwlBear.Adventure.Location

  defmodule Location do
    defstruct %{
      name: nil,
      danger: 0,
      color: nil,
      actions: []
    }
  end

  def find_location(name) do
    case name do
      :dungeon -> {:ok, %Location{name: name, danger: 10, color: :slate, actions: [:enter, :search]}}
      :forest -> {:ok, %Location{name: name, danger: 7, color: :jade, actions: [:enter, :search, :forage]}}
      :village -> {:ok, %Location{name: name, danger: 2, color: :ivory, actions: [:forage]}}
      :mountain -> {:ok, %Location{name: name, danger: 3, color: :earth, actions: [:climb, :forage]}}
      _ -> {:error, {:no_such_place, name}}
    end
  end

  def search_for_food(%Location{name: name, actions: actions}) do
    case :forage in actions do
      true -> {:ok, "A delicious peasant!"}
      false -> {:error, {:no_food_here, name}}
    end
  end



end
