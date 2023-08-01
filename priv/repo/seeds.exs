# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Fly.Repo.insert!(%Fly.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Fly.Repo

{:ok, organization} = Fly.Organizations.create_organization(%{
  name: "Fly",
  stripe_customer_id: "cus_1234"
})

{:ok, _paid_invoice} = Fly.Billing.create_invoice(organization, %{
  due_date: ~D[2023-06-01],
  invoiced_at: ~U[2021-08-01 00:00:00Z],
  stripe_id: "abcd"
})

{:ok, invoice} = Fly.Billing.create_invoice(organization, %{
  due_date: ~D[2023-07-01],
  invoiced_at: nil,
  stripe_id: nil
})

{:ok, invoice_item_1} = Fly.Billing.create_invoice_item(
  invoice, %{
    amount: 1200,
    description: "VM usage",
  }
)

invoice_item_2 = Repo.insert!(%Fly.Billing.InvoiceItem{
  amount: 2345,
  description: "VM Network usage",
  invoice_id: invoice.id
})

Fly.Billing.get_invoice!(invoice.id)
