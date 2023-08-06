defmodule Fly.BroadwayEctoSandbox do
  @moduledoc """
  It allows Broadway to execute tests concurrently.
  https://hexdocs.pm/broadway/Broadway.html#module-testing-with-ecto
  """
  def attach(repo) do
    events = [
      [:broadway, :processor, :start],
      [:broadway, :batch_processor, :start]
    ]

    :telemetry.attach_many({__MODULE__, repo}, events, &__MODULE__.handle_event/4, %{repo: repo})
  end

  def handle_event(_event_name, _event_measurement, %{messages: messages}, %{repo: repo}) do
    with [%Broadway.Message{metadata: %{ecto_sandbox: pid, mimic_modules: mimic_modules}} | _] <-
           messages do
      Enum.each(mimic_modules, &Mimic.allow(&1, pid, self()))

      Ecto.Adapters.SQL.Sandbox.allow(repo, pid, self())
    end

    :ok
  end
end
