defmodule Fly.StripeTest do
  use ExUnit.Case, async: true

  doctest Fly.Stripe
  doctest Fly.Stripe.Invoice
  doctest Fly.Stripe.InvoiceItem
end
