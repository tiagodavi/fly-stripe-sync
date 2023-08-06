defmodule Fly.Stripe.InvoiceScheduler do
  @moduledoc """
  Simple scheduler to close an Invoice on its due date.
  """

  use GenServer

  alias Fly.Billing

  def start_link(opts) do
    interval = Keyword.fetch!(opts, :interval)

    GenServer.start_link(__MODULE__, interval, name: __MODULE__)
  end

  @impl true
  def init(interval) do
    schedule_work(interval)

    {:ok, interval}
  end

  @impl true
  def handle_info(:work, interval) do
    close_invoices()
    schedule_work(interval)

    {:noreply, interval}
  end

  defp schedule_work(interval) do
    Process.send_after(self(), :work, interval)
  end

  defp close_invoices do
    updated_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    invoiced_at =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    Date.utc_today()
    |> Billing.list_due_invoices()
    |> Enum.map(fn invoice ->
      [
        id: invoice.id,
        inserted_at: updated_at,
        updated_at: updated_at,
        invoiced_at: invoiced_at
      ]
    end)
    |> Billing.close_due_invoices()
  end
end
