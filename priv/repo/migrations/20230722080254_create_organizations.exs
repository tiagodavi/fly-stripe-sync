defmodule Fly.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :stripe_customer_id, :string

      timestamps()
    end

    create index(:organizations, [:stripe_customer_id], unique: true)
  end
end
