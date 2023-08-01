defmodule Fly.BillingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fly.Billing` context.
  """

  @doc """
  Generate a invoice.
  """
  def invoice_fixture(organization, attrs \\ %{}) do
    attrs = attrs
            |> Enum.into(%{
              due_date: ~D[2023-07-22],
              invoiced_at: ~U[2023-07-22 12:39:00Z],
              stripe_id: "some stripe_id"
            })

    {:ok, invoice} = Fly.Billing.create_invoice(organization, attrs)

    invoice
  end
end
