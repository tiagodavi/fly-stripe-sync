defmodule Fly.BillingTest do
  use Fly.DataCase

  alias Fly.Billing

  describe "invoices" do
    alias Fly.Billing.Invoice

    import Fly.BillingFixtures
    import Fly.OrganizationFixtures

    @invalid_attrs %{due_date: nil, invoiced_at: nil, stripe_id: nil}

    setup do
      org = organization_fixture()

      {:ok, org: org}
    end

    test "list_invoices/0 returns all invoices", %{org: org} do
      invoice = invoice_fixture(org)
      invoice = Billing.get_invoice!(invoice.id, preload: [:organization, :invoice_items])
      assert Billing.list_invoices(preload: [:organization, :invoice_items]) == [invoice]
    end

    test "get_invoice!/1 returns the invoice with given id", %{org: org} do
      invoice_fixture = invoice_fixture(org)
      invoice = Billing.get_invoice!(invoice_fixture.id, preload: :organization)
      assert invoice.id == invoice_fixture.id
      assert invoice.organization == org
    end

    test "create_invoice/1 with valid data creates a invoice", %{org: org} do
      valid_attrs = %{
        due_date: ~D[2023-07-22],
        invoiced_at: ~U[2023-07-22 12:39:00Z],
        stripe_id: "some stripe_id"
      }

      assert {:ok, %Invoice{} = invoice} = Billing.create_invoice(org, valid_attrs)
      assert invoice.due_date == ~D[2023-07-22]
      assert invoice.invoiced_at == ~U[2023-07-22 12:39:00Z]
      assert invoice.stripe_id == "some stripe_id"
    end

    test "create_invoice/1 with invalid data returns error changeset", %{org: org} do
      assert {:error, %Ecto.Changeset{}} = Billing.create_invoice(org, @invalid_attrs)
    end

    test "update_invoice/2 with valid data updates the invoice", %{org: org} do
      invoice = invoice_fixture(org)

      update_attrs = %{
        due_date: ~D[2023-07-23],
        invoiced_at: ~U[2023-07-23 12:39:00Z],
        stripe_id: "some updated stripe_id"
      }

      assert {:ok, %Invoice{} = invoice} = Billing.update_invoice(invoice, update_attrs)
      assert invoice.due_date == ~D[2023-07-23]
      assert invoice.invoiced_at == ~U[2023-07-23 12:39:00Z]
      assert invoice.stripe_id == "some updated stripe_id"
    end

    test "update_invoice/2 with invalid data returns error changeset", %{org: org} do
      invoice = invoice_fixture(org)
      assert {:error, %Ecto.Changeset{}} = Billing.update_invoice(invoice, @invalid_attrs)
      assert invoice == Billing.get_invoice!(invoice.id, preload: :organization)
    end

    test "delete_invoice/1 deletes the invoice", %{org: org} do
      invoice = invoice_fixture(org, preload: :organization)
      assert {:ok, %Invoice{}} = Billing.delete_invoice(invoice)
      assert_raise Ecto.NoResultsError, fn -> Billing.get_invoice!(invoice.id) end
    end

    test "change_invoice/1 returns a invoice changeset", %{org: org} do
      invoice = invoice_fixture(org)
      assert %Ecto.Changeset{} = Billing.change_invoice(invoice)
    end

    test "list_due_invoices/1 returns due invoices", %{org: org} do
      due_date = Date.utc_today()

      due_invoice =
        invoice_fixture(org, %{
          due_date: Date.add(due_date, -1),
          invoiced_at: nil,
          stripe_id: nil
        })

      _extra_invoice =
        invoice_fixture(org, %{
          due_date: Date.add(due_date, 1),
          invoiced_at: nil,
          stripe_id: nil
        })

      assert [%Billing.Invoice{id: id}] = Billing.list_due_invoices(due_date)
      assert id == due_invoice.id
    end

    test "close_due_invoices/1 closes due invoices", %{org: org} do
      due_date = Date.utc_today()

      invoiced_at =
        DateTime.utc_now()
        |> DateTime.truncate(:second)

      updated_at =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)

      due_invoice =
        invoice_fixture(org, %{
          due_date: due_date,
          invoiced_at: nil,
          stripe_id: nil
        })

      _extra_invoice =
        invoice_fixture(org, %{
          due_date: Date.add(due_date, 1),
          invoiced_at: nil,
          stripe_id: nil
        })

      input = [
        id: due_invoice.id,
        stripe_id: "anything",
        invoiced_at: invoiced_at,
        inserted_at: updated_at,
        updated_at: updated_at
      ]

      assert {1, [%Billing.Invoice{} = invoice]} = Billing.close_due_invoices([input])
      assert invoice.id == due_invoice.id
      assert invoice.invoiced_at == invoiced_at
      assert length(Billing.list_invoices()) == 2
    end

    test "list_not_due_invoices_by_orgs/2 returns not due invoices", %{org: org} do
      due_date = Date.utc_today()

      %{id: invoice_id, organization_id: organization_id} =
        invoice_fixture(org, %{
          due_date: due_date,
          invoiced_at: nil,
          stripe_id: nil
        })

      assert [%{id: ^invoice_id, organization_id: ^organization_id, stripe_id: nil}] =
               Billing.list_not_due_invoices_by_orgs([org.id], due_date)
    end
  end
end
