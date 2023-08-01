defmodule Fly.OrganizationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fly.Organizations` context.
  """

  @doc """
  Generate an org.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, org} =
      attrs
      |> Enum.into(%{
        name: "some org name",
        stripe_customer_id: "some stripe_customer_id",
      })
      |> Fly.Organizations.create_organization()

    org
  end
end
