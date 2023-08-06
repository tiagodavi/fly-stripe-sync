defmodule Fly.Stripe.SyncService do
  @moduledoc """
  A synchronization service that fetches usage data from queues and processes it to generate invoices in real-time.

  Decisions:

    Every producer will try to satisfy the demand of every processor
    so we can increase producer concurrency if the queues become a bottleneck in the future.

    For most APIs, Stripe allows up to 100 read operations per second
    and 100 write operations per second in live mode, and 25 operations
    per second for each in test mode so we defined the rate limit option
    to avoid goind beyond Stripe limit.

    https://stripe.com/docs/rate-limits
  """

  use Broadway

  alias Broadway.Message
  alias Fly.Billing
  alias Fly.Organizations
  alias Fly.Organizations.Usage
  alias Fly.Stripe

  @batch_size 100
  @concurrency System.schedulers_online() * 2
  @interval 1_000
  @min_demand 50
  @max_demand 100

  def start_link(opts) do
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    concurrency = Keyword.get(opts, :concurrency, @concurrency)
    min_demand = Keyword.get(opts, :min_demand, @min_demand)
    max_demand = Keyword.get(opts, :max_demand, @max_demand)
    interval = Keyword.get(opts, :interval, @interval)

    producer_module = Application.fetch_env!(:fly, :producer_module)
    producer_options = Application.get_env(:fly, :producer_options, [])

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {producer_module, producer_options},
        transformer: {__MODULE__, :transform, []},
        concurrency: 1,
        rate_limiting: [
          allowed_messages: max_demand,
          interval: interval
        ]
      ],
      processors: [
        default: [concurrency: concurrency, min_demand: min_demand, max_demand: max_demand]
      ],
      batchers: [
        stripe: [concurrency: concurrency, batch_size: batch_size]
      ]
    )
  end

  def prepare_messages(messages, _context) do
    accumulator =
      Enum.reduce(messages, %{orgs: [], messages: []}, fn %Message{data: data} = message, acc ->
        %Usage{}
        |> Usage.changeset(data)
        |> Ecto.Changeset.apply_action(:create)
        |> case do
          {:ok, %Usage{} = usage} ->
            %{
              acc
              | messages: [Message.put_data(message, usage) | acc.messages],
                orgs: [usage.organization_id | acc.orgs]
            }

          _ ->
            %{
              acc
              | messages: [Message.failed(message, :bad_format) | acc.messages],
                orgs: [nil | acc.orgs]
            }
        end
      end)

    org_ids =
      accumulator.orgs
      |> Enum.reject(&(&1 == nil))
      |> Enum.uniq()

    accumulator.messages
    |> Enum.map(add_invoice_to_message(org_ids))
    |> Enum.reverse()
  end

  # TO-DO: Should we send errors to AppSignal?
  def handle_message(_processor_name, message, _context) do
    message = Message.update_data(message, &process_data/1)

    case message.data do
      %Usage{} ->
        Message.put_batcher(message, :stripe)

      error ->
        Message.failed(message, error)
    end
  end

  def handle_batch(:stripe, messages, _batch_info, _context) do
    updated_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    accumulator =
      Enum.reduce(messages, %{invoices: [], invoice_items: []}, fn %Message{data: data}, acc ->
        %{
          acc
          | invoices: [
              [
                id: data.invoice_id,
                stripe_id: data.stripe_id,
                inserted_at: updated_at,
                updated_at: updated_at
              ]
              | acc.invoices
            ],
            invoice_items: [
              [
                invoice_id: data.invoice_id,
                amount: data.amount,
                description: data.description,
                inserted_at: updated_at,
                updated_at: updated_at
              ]
              | acc.invoice_items
            ]
        }
      end)

    Billing.upsert_invoices(accumulator.invoices)
    Billing.upsert_invoice_items(accumulator.invoice_items)

    messages
  end

  defp process_data(%Usage{stripe_id: stripe_id} = usage) when is_binary(stripe_id) do
    usage
  end

  defp process_data(%Usage{stripe_id: stripe_id} = usage) when is_nil(stripe_id) do
    with {:ok, %Stripe.Invoice{id: id}} <-
           Stripe.Invoice.create(%{customer: usage.stripe_customer_id}),
         {:ok, %Stripe.InvoiceItem{}} <-
           Stripe.InvoiceItem.create(%{
             invoice: id,
             quantity: usage.quantity,
             unit_amount_decimal: usage.unit_amount_decimal
           }) do
      %Usage{usage | stripe_id: id}
    else
      _ ->
        :bad_sync
    end
  end

  defp process_data(_failed_data), do: :bad_format

  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end

  # TO-DO: Something with the failed messages
  def ack(:ack_id, _successful, _failed), do: :ok

  defp add_invoice_to_message(org_ids) do
    today = Date.utc_today()
    organizations = Organizations.list_organizations_by_ids(org_ids)
    invoices = Billing.list_not_due_invoices_by_orgs(org_ids, today)

    fn %Message{data: data} = message ->
      if message.status == :ok do
        organization = Enum.find(organizations, &(&1.id == data.organization_id))
        invoice = Enum.find(invoices, &(&1.organization_id == data.organization_id))

        if invoice do
          Message.put_data(message, %Usage{
            data
            | invoice_id: invoice.id,
              stripe_id: invoice.stripe_id
          })
        else
          {:ok, invoice} =
            Billing.create_invoice(organization, %{
              due_date: Date.add(today, 30),
              invoiced_at: nil,
              stripe_id: nil
            })

          Message.put_data(message, %Usage{
            data
            | invoice_id: invoice.id
          })
        end
      else
        message
      end
    end
  end
end
