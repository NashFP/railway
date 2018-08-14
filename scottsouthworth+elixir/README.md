# OwlBear

OwlBear handles both the happy paths and the error paths of functions within a single Elixir pipeline.

  But the poor OwlBear is a terribly conflicted creature, light and free like an `{:ok, owl}`, heavy and brutal
  like an angry `{:error, bear}`.

### Run
  _...to run functions on the happy path..._

  Functions are generally expected to return tuples such as `{:ok, value}` or `{error, value}`.

  Functions that don't return a result tuple can be used with keyword option `bare: true`.
  This will wrap return values in a result tuple of form `{:ok, value}`.

  Functions that generate exceptions can be trapped as error tuples using the option `try: true`.

  Results can be named and referenced later in the pipeline using the option `name: atom()`.

  Normally, the OwlBear just runs along. A result tuple is released when the OwlBears decides to `eol`.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> run(fn msg -> msg <> ", let's be friends!" end, bare: true)
      ...> |> eol()
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
      ...> |> eol()
      {:error, "Hello OwlBear, too many bunnies nearby!"}

  Note that the last two functions are skipped because OwlBear is no longer
  travelling on the happy path. An OwlBear must be pretty happy to keep running.

### Check
  _...anything that comes along..._

  No matter what's going on, OwlBear can always check it out.
  This could get him in trouble, though, wracking up multiple errors.

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> check(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> check(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> check(fn _ -> "Not dead yet?" end, bare: true)
      ...> |> check(fn _ -> {:error, "Run away! Run away!"} end)
      ...> |> check(fn _ -> {:ok, "Are we safe now?"} end)
      ...> |> eol()
      {:error, "Are we safe now?"}

  When OwlBear checks something, he will always pass along the value, but cannot
  recover from the error path.

### Fix
  _...to crush the errors in our way..._

  OwlBear can find his way back to the happy path, by taking errors down (fixing the problem).

      iex> import OwlBear
      iex> "Hello"
      ...> |> run(fn msg -> {:ok, msg <> " OwlBear"} end)
      ...> |> check(fn _ -> {:ok, "A delicious adventuer!"} end)
      ...> |> check(fn _ -> {:error, "This guy has a sword!"} end)
      ...> |> fix(fn _ -> {:ok, "Adventurer parts are everywhere."} end)
      ...> |> fix(fn _ -> {:ok, "This might be overkill."} end)
      ...> |> fix(fn _ -> {:ok, "I think we got him."} end)
      ...> |> eol()
      {:ok, "Adventurer parts are everywhere."}

  Fixs are only executed when on the `:error` path. A successful fix will bring OwlBear back to the `:ok` world.


grr
## Installation

```elixir
def deps do
  [
    {:owlbear, "~> 3.0.0"}
  ]
end
```

