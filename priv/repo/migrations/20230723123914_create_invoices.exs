defmodule Fly.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :stripe_id, :string
      add :due_date, :date
      add :invoiced_at, :utc_datetime
      add :organization_id, references(:organizations)

      timestamps()
    end
  end
end
