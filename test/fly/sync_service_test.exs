defmodule Fly.SyncServiceTest do
  use Fly.DataCase, async: true
  use Mimic

  alias Fly.Billing
  alias Fly.Organizations.Usage
  alias Fly.Stripe.SyncService

  setup do
    service_pid =
      start_link_supervised!(
        {SyncService,
         [
           batch_size: 2,
           concurrency: 2,
           min_demand: 5,
           max_demand: 10,
           interval: 100
         ]},
        restart: :temporary
      )

    [service_pid: service_pid]
  end

  describe "stripe synchronization" do
    import Fly.BillingFixtures
    import Fly.OrganizationFixtures

    test "it creates an invoice and stripe when invoice is not available" do
      organization =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      message = %{
        "organization_id" => organization.id,
        "stripe_customer_id" => organization.stripe_customer_id,
        "description" => "Usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      ref =
        Broadway.test_message(SyncService, message,
          metadata: %{ecto_sandbox: self(), mimic_modules: []}
        )

      assert_receive {:ack, ^ref, [%{data: %Usage{} = usage}], []}
      assert is_integer(usage.invoice_id)
      assert is_binary(usage.stripe_id)
      assert usage.organization_id == organization.id
      assert %Billing.Invoice{} = Billing.get_invoice!(usage.invoice_id)
    end

    test "it uses the same invoice and stripe when it is available" do
      organization =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      invoice =
        invoice_fixture(organization, %{
          due_date: Date.utc_today(),
          invoiced_at: nil,
          stripe_id: "dcba"
        })

      message = %{
        "organization_id" => organization.id,
        "stripe_customer_id" => organization.stripe_customer_id,
        "description" => "Usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      ref =
        Broadway.test_message(SyncService, message,
          metadata: %{ecto_sandbox: self(), mimic_modules: []}
        )

      assert_receive {:ack, ^ref, [%{data: %Usage{} = usage}], []}
      assert invoice.id == usage.invoice_id
      assert invoice.stripe_id == usage.stripe_id
      assert organization.id == usage.organization_id

      assert %Billing.Invoice{} = Billing.get_invoice!(usage.invoice_id)
    end

    test "it handles multiple messages and creates invoice items" do
      organization_1 =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      organization_2 =
        organization_fixture(%{
          name: "Fly Branch",
          stripe_customer_id: "fly_4321"
        })

      invoice =
        invoice_fixture(organization_1, %{
          due_date: Date.utc_today(),
          invoiced_at: nil,
          stripe_id: "dcba"
        })

      message_1 = %{
        "organization_id" => organization_1.id,
        "stripe_customer_id" => organization_1.stripe_customer_id,
        "description" => "Org 1 usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      message_2 = %{
        "organization_id" => organization_2.id,
        "stripe_customer_id" => organization_2.stripe_customer_id,
        "description" => "Org 2 usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      ref =
        Broadway.test_batch(SyncService, [message_1, message_2],
          metadata: %{ecto_sandbox: self(), mimic_modules: []}
        )

      assert_receive {:ack, ^ref, messages, []}
      message_1 = Enum.find(messages, &(&1.data.organization_id == organization_1.id))
      message_2 = Enum.find(messages, &(&1.data.organization_id == organization_2.id))

      assert invoice.id == message_1.data.invoice_id
      assert invoice.stripe_id == message_1.data.stripe_id

      assert is_integer(message_2.data.invoice_id)
      assert is_binary(message_2.data.stripe_id)

      assert %Billing.Invoice{invoice_items: [_invoice_item_1]} =
               Billing.get_invoice!(message_1.data.invoice_id, preload: [:invoice_items])

      assert %Billing.Invoice{invoice_items: [_invoice_item_2]} =
               Billing.get_invoice!(message_2.data.invoice_id, preload: [:invoice_items])
    end

    test "it closes a due invoice automatically" do
      organization =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      invoice =
        invoice_fixture(organization, %{
          due_date: Date.utc_today(),
          invoiced_at: nil,
          stripe_id: "dcba"
        })

      invoice_scheduler =
        start_link_supervised!({Fly.Stripe.InvoiceScheduler, interval: 100}, restart: :temporary)

      Ecto.Adapters.SQL.Sandbox.allow(Fly.Repo, self(), invoice_scheduler)

      Process.sleep(150)

      assert %Billing.Invoice{invoiced_at: invoiced_at} = Billing.get_invoice!(invoice.id)
      refute is_nil(invoiced_at)
    end

    test "it fails to build usage structure with bad format" do
      message = %{
        "description" => "Usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      ref =
        Broadway.test_message(SyncService, message,
          metadata: %{ecto_sandbox: self(), mimic_modules: []}
        )

      assert_receive {:ack, ^ref, [], [%Broadway.Message{status: {:failed, :bad_format}}]}
    end

    test "it fails to sync data to stripe when creating invoice" do
      Fly.Stripe.Invoice
      |> expect(:create, 1, fn %{customer: "cus_4321"} ->
        {:error, %Fly.Stripe.Error{message: "some error"}}
      end)

      organization =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      message = %{
        "organization_id" => organization.id,
        "stripe_customer_id" => organization.stripe_customer_id,
        "description" => "Usage data",
        "amount" => 50,
        "unit_amount_decimal" => 2.5,
        "quantity" => 3
      }

      ref =
        Broadway.test_message(SyncService, message,
          metadata: %{ecto_sandbox: self(), mimic_modules: [Fly.Stripe.Invoice]}
        )

      assert_receive {:ack, ^ref, [], [%Broadway.Message{status: {:failed, :bad_sync}}]}
    end

    test "it fails to sync data to stripe when creating invoice item" do
      unit_amount_decimal = Decimal.new("9.5")

      Fly.Stripe.InvoiceItem
      |> expect(:create, 1, fn %{
                                 quantity: 25,
                                 unit_amount_decimal: ^unit_amount_decimal
                               } ->
        {:error, %Fly.Stripe.Error{message: "some error"}}
      end)

      organization =
        organization_fixture(%{
          name: "Acme",
          stripe_customer_id: "cus_4321"
        })

      message = %{
        "organization_id" => organization.id,
        "stripe_customer_id" => organization.stripe_customer_id,
        "description" => "Usage data",
        "amount" => 42,
        "unit_amount_decimal" => 9.5,
        "quantity" => 25
      }

      ref =
        Broadway.test_message(SyncService, message,
          metadata: %{ecto_sandbox: self(), mimic_modules: [Fly.Stripe.InvoiceItem]}
        )

      assert_receive {:ack, ^ref, [], [%Broadway.Message{status: {:failed, :bad_sync}}]}
    end
  end
end
