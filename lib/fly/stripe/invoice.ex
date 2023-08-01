defmodule Fly.Stripe.Invoice do
  @moduledoc """
  Stripe Invoice
  """

  use Fly.Stripe.Helpers

  # https://stripe.com/docs/api/invoices
  defstruct [:id, :customer, :total]

  @doc """
  Create an InvoiceItem

  ## Examples

    iex> Fly.Stripe.Invoice.create(%{id: "abcd", customer: "cus_1234"})
    {:ok, %Fly.Stripe.Invoice{id: "abcd", customer: "cus_1234"}}

    iex> Fly.Stripe.Invoice.create(%{id: "abcd"})
    {:error, %Fly.Stripe.Error{message: "customer is required"}}
  """
  def create(params \\ %{})
  def create(%{customer: _customer} = params), do: create_record(params)
  def create(_params), do: {:error, %Fly.Stripe.Error{message: "customer is required"}}

  @doc """
  Retrieve an Invoice

  ## Examples

    iex> Fly.Stripe.Invoice.retrieve("abcd", %{customer: "cus_1234"})
    %Fly.Stripe.Invoice{id: "abcd", customer: "cus_1234"}

    iex> Fly.Stripe.Invoice.retrieve(nil)
    ** (Fly.Stripe.Error) id is required
  """
  def retrieve(id, params \\ %{})
  def retrieve(nil, _params), do: raise(Fly.Stripe.Error, message: "id is required")
  def retrieve(id, params), do: retrieve_record(id, params)

  @doc """
  Update an Invoice

  ## Examples

    iex> Fly.Stripe.Invoice.update(%Fly.Stripe.Invoice{id: "abcd", customer: "cus_1234"}, %{customer: "cus_xyz"})
    {:ok, %Fly.Stripe.Invoice{id: "abcd", customer: "cus_xyz"}}
  """
  def update(invoice, params), do: update_record(invoice, params)
end
