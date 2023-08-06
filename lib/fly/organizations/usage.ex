defmodule Fly.Organizations.Usage do
  @moduledoc """
  It represents a usage data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  embedded_schema do
    field :amount, :integer
    field :description, :string
    field :invoice_id, :id
    field :organization_id, :id
    field :quantity, :integer
    field :stripe_id, :string
    field :stripe_customer_id, :string
    field :unit_amount_decimal, :decimal
  end

  @fields [
    :description,
    :amount,
    :invoice_id,
    :organization_id,
    :quantity,
    :stripe_id,
    :stripe_customer_id,
    :unit_amount_decimal
  ]

  @required [
    :description,
    :amount,
    :organization_id,
    :quantity,
    :stripe_customer_id,
    :unit_amount_decimal
  ]

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
