defmodule Fly.Stripe.Helpers do
  @moduledoc """
  Consolidate common functionality into single helper module
  """

  defmacro __using__(_opts) do
    quote do
      @doc false
      def create_record(params \\ %{}) do
        # If an ID isn't passed, generate one
        params = Map.put_new(params, :id, generate_id())
        {:ok, struct(__MODULE__, params)}
      end

      @doc false
      def retrieve_record(id, params \\ %{}) do
        params = Map.put(params, :id, id)
        struct(__MODULE__, params)
      end

      @doc false
      def update_record(record, params) do
        record = Map.merge(record, params)
        {:ok, record}
      end

      @doc """
      Helper method for generating an id
      """
      def generate_id do
        unix_timestamp = DateTime.utc_now() |> DateTime.to_unix()
        "inv_#{unix_timestamp}"
      end
    end
  end
end
