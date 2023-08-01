defmodule Fly.Stripe.InvoiceItem do
  @moduledoc """
  Stripe Invoice Item
  """

  use Fly.Stripe.Helpers

  defstruct [:id, :invoice, unit_amount_decimal: 0.0, quantity: 0]

  @doc """
  Create an InvoiceItem

  ## Examples

    iex> Fly.Stripe.InvoiceItem.create(%{id: "abcd", invoice: "inv_1234", unit_amount_decimal: 2.5, quantity: 1})
    {:ok, %Fly.Stripe.InvoiceItem{id: "abcd", invoice: "inv_1234", unit_amount_decimal: 2.5, quantity: 1}}
  """
  def create(params \\ %{}), do: create_record(params)

  @doc """
  Retrieve an InvoiceItem

  ## Examples

    iex> Fly.Stripe.InvoiceItem.retrieve("abcd", %{invoice: "inv_1234"})
    %Fly.Stripe.InvoiceItem{id: "abcd", invoice: "inv_1234", unit_amount_decimal: 0.0, quantity: 0}

    iex> Fly.Stripe.InvoiceItem.retrieve(nil)
    ** (Fly.Stripe.Error) id is required
  """
  def retrieve(id, params \\ %{})
  def retrieve(nil, _params), do: raise(Fly.Stripe.Error, message: "id is required")
  def retrieve(id, params), do: retrieve_record(id, params)

  @doc """
  Update an InvoiceItem

  ## Examples

    iex> Fly.Stripe.InvoiceItem.update(%Fly.Stripe.InvoiceItem{id: "abcd", invoice: "inv_1234"}, %{invoice: "inv_xyz"})
    {:ok, %Fly.Stripe.InvoiceItem{id: "abcd", invoice: "inv_xyz"}}
  """
  def update(invoice_item, params), do: update_record(invoice_item, params)
end
