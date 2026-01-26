defmodule ButtonLog.Repo.Migrations.AddStripePriceIdsToSubscriptionPlans do
  use Ecto.Migration

  def change do
    alter table(:subscription_plans) do
      add :stripe_product_id, :string
      add :stripe_price_id_monthly, :string
      add :stripe_price_id_yearly, :string
    end

    create index(:subscription_plans, [:stripe_product_id])
  end
end
