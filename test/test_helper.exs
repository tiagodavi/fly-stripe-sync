Mimic.copy(Fly.Stripe.Invoice)
Mimic.copy(Fly.Stripe.InvoiceItem)

ExUnit.start()
Fly.BroadwayEctoSandbox.attach(Fly.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Fly.Repo, :manual)
