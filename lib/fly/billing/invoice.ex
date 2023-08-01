defmodule Fly.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  @cast ~w(
    stripe_id
    due_date
    invoiced_at
  )a
  @required ~w(
    due_date
  )a

  schema "invoices" do
    field :due_date, :date
    field :invoiced_at, :utc_datetime
    field :stripe_id, :string

    has_many :invoice_items, Fly.Billing.InvoiceItem
    belongs_to :organization, Fly.Organizations.Organization

    timestamps()
  end

  def organization_changeset(invoice, %Fly.Organizations.Organization{} = organization, attrs) do
    invoice
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> put_assoc(:organization, organization)
  end
  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, @cast)
    |> validate_required(@required)
  end
end
