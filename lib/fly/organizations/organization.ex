defmodule Fly.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :stripe_customer_id, :string

    has_many :invoices, Fly.Billing.Invoice

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :stripe_customer_id])
    |> validate_required([:name, :stripe_customer_id])
    |> unique_constraint(:stripe_customer_id)
  end
end
