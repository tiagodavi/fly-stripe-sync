defmodule Fly.Stripe do
  @moduledoc """
  # Stripe API module

  This is a thin module meant to look a lot like the ["Stripe for Elixir" library](https://github.com/beam-community/stripity-stripe) ([hex docs](https://hexdocs.pm/stripity_stripe/Stripe.html#content)), which the most commonly used Stripe library for Elixir.

  This is meant to help you focus on the problem, rather than learning the Stripe API.

  Feel free to modify these modules. For example, add more errors, etc..

  There are a few modules:
  - Fly.Stripe
  - Fly.Stripe.Invoice
  - Fly.Stripe.InvoiceItem

  ## Usage

  ### Invoice

  The Fly.Stripe.Invoice module is documented and we suggest looking there.

  ```elixir
  # create
  invoice = Fly.Stripe.Invoice.create(%{customer: "cus_1234567"})

  # retrieve
  invoice = Fly.Stripe.InvoiceItem.retrieve(
    invoice.id,
    %{
      customer: "cus_1234567"
    }
  )
  ```

  ## InvoiceItem

  The Fly.Stripe.InvoiceItem module is documented and we suggest looking there.

  ```elixir
  # create
  invoice = Fly.Stripe.Invoice.create(%{customer: "cus_1234567"})

  ## Note: if you're looking at [the docs for creating an Invoiceitem](https://hexdocs.pm/stripity_stripe/Stripe.Invoiceitem.html#create/2)
  ## you might notice that currency and customer are required arguments. We're not going to
  ## enforce that rule with out implementation.
  invoice_item = Fly.Stripe.InvoiceItem.create(
    %{
      invoice: invoice.id,
      unit_amount_decimal: 0.1,
      quantity: 1
    }
  )

  # retrieve
  invoice_item = Fly.Stripe.InvoiceItem.retrieve(
    invoice_item.id,
    %{
      unit_amount_decimal: 2.0,
      quantity: 20
    }
  )
  ```

  ## Stubbing, Errors, and Slow Responses

  ```elixir
  # These stubbing strategies are available for both Invoice and InvoiceItem.
  # We would suggest using these to prove things work in tests or for
  # tinkering in the iex console.

  Fly.Stripe.slow_with(1000) do
    Fly.Stripe.Invoice.retrieve("inv_1234") # waits 1 second
  end

  Fly.Stripe.error_with(fn ->
    Fly.Stripe.Invoice.retrieve(%{id: "abcd", customer: "cus_1234"})
  end, %Fly.Stripe.Error{message: "no error"})

  Fly.Stripe.error_with(fn ->
    Fly.Stripe.Invoice.retrieve(nil)
  end, %Fly.Stripe.Error{message: "uhoh error time"})
  ** (Fly.Stripe.Error) uh-oh error time
  ```

  """

  @doc """
  Delay the execution of a function by a given number of milliseconds

  ## Examples

  iex> Fly.Stripe.slow_with(fn ->
  iex>   Fly.Stripe.Invoice.create(%{id: "abcd", customer: "cus_1234"})
  iex> end, 1000)

  {:ok, %Fly.Stripe.Invoice{id: "abcd", customer: "cus_1234"}}
  """
  def slow_with(func, time_milliseconds) do
    :timer.sleep(time_milliseconds)

    func.()
  end

  @doc """
  Replace any errors that occur with the provided error

  ## Examples

  No error:

  iex> Fly.Stripe.error_with(fn ->
  ...>   Fly.Stripe.Invoice.create(%{id: "abcd", customer: "cus_1234"})
  ...> end, %Fly.Stripe.Error{message: "bubble tea"})

  {:ok, %Fly.Stripe.Invoice{id: "abcd", customer: "cus_1234"}}


  Trigger error:
  iex> Fly.Stripe.error_with(fn ->
  ...>   Fly.Stripe.Invoice.retrieve(nil)
  ...> end, %Fly.Stripe.Error{message: "bubble tea"})
  ** (Fly.Stripe.Error) bubble tea
  """
  def error_with(func, error) do
    try do
      func.()
    rescue
      _e -> raise error.__struct__, message: error.message
    end
  end
end
