defmodule Fly.Stripe.EventSimulator do
  @moduledoc """
  An event simulator to generate samples of client usage data.
  """
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:producer, opts}
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  def handle_cast({:usage, usage}, state) do
    {:noreply, [usage], state}
  end

  @spec push(name :: atom(), usage :: map()) :: :ok
  def push(name, usage) when is_atom(name) and is_map(usage) do
    GenStage.cast(name, {:usage, usage})
  end
end
