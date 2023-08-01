defmodule Fly.Repo.Migrations.CreateInvoiceItems do
  use Ecto.Migration

  def change do
    create table(:invoice_items) do
      add :description, :text
      add :amount, :integer
      add :invoice_id, references(:invoices)

      timestamps()
    end
  end
end
