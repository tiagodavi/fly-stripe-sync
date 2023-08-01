defmodule Fly.Billing do
  @moduledoc """
  The Billing context.

  This file was generated using:
  `mix phx.gen.context Billing Invoice invoices`
  """

  import Ecto.Query, warn: false
  alias Fly.Repo

  alias Fly.Billing.Invoice
  alias Fly.Billing.InvoiceItem
  alias Fly.Organizations.Organization

  defmodule BillingError do
    defexception message: "billing error"
  end

  @doc """
  Returns the list of invoices.

  ## Examples

      iex> list_invoices()
      [%Invoice{}, ...]

  """
  def list_invoices(opts \\ []) do
    preload = Keyword.get(opts, :preload, [:invoice_items])

    from(Invoice, preload: ^preload)
    |> Repo.all()
  end

  @doc """
  Gets a single invoice.

  Raises `Ecto.NoResultsError` if the Invoice does not exist.

  ## Examples

      iex> get_invoice!(123)
      %Invoice{}

      iex> get_invoice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invoice!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(i in Invoice, preload: ^preload)
    |> Repo.get!(id)
  end

  @doc """
  Creates a invoice.

  ## Examples

      iex> create_invoice(%{field: value})
      {:ok, %Invoice{}}

      iex> create_invoice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invoice(%Organization{} = organization, attrs \\ %{}) do
    %Invoice{}
    |> Invoice.organization_changeset(organization, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a invoice.

  ## Examples

      iex> update_invoice(invoice, %{field: new_value})
      {:ok, %Invoice{}}

      iex> update_invoice(invoice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invoice.

  ## Examples

      iex> delete_invoice(invoice)
      {:ok, %Invoice{}}

      iex> delete_invoice(invoice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invoice(%Invoice{} = invoice) do
    Repo.delete(invoice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invoice changes.

  ## Examples

      iex> change_invoice(invoice)
      %Ecto.Changeset{data: %Invoice{}}

  """
  def change_invoice(%Invoice{} = invoice, attrs \\ %{}) do
    Invoice.changeset(invoice, attrs)
  end

  @doc """
  Add Invoice Item to Invoice
  """
  def create_invoice_item(%Invoice{} = invoice, attrs) do
    InvoiceItem.invoice_changeset(invoice, %InvoiceItem{}, attrs)
    |> Repo.insert()
  end
end
