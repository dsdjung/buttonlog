defmodule ButtonLog.Repo.Migrations.AddPaymentMethods do
  use Ecto.Migration

  def change do
    # Create payment_methods table for storing customer payment methods
    create table(:payment_methods, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      # Payment provider details
      add :payment_provider, :string, null: false  # "stripe"
      add :payment_provider_method_id, :string, null: false  # Stripe payment method ID (pm_xxx)
      add :payment_provider_customer_id, :string  # Stripe customer ID (cus_xxx)

      # Card details (stored for display purposes, not for charging)
      add :card_brand, :string  # "visa", "mastercard", etc.
      add :card_last_four, :string  # Last 4 digits
      add :card_exp_month, :integer
      add :card_exp_year, :integer

      # Status
      add :is_default, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false

      # Metadata
      add :billing_name, :string
      add :billing_email, :string
      add :billing_address, :map

      timestamps()
    end

    # Create invoices table for billing history
    create table(:invoices, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :user_subscription_id, references(:user_subscriptions, type: :uuid, on_delete: :nilify_all)

      # Invoice details
      add :invoice_number, :string, null: false
      add :status, :string, null: false  # "draft", "open", "paid", "void", "uncollectible"
      add :amount_due, :decimal, precision: 10, scale: 2, null: false
      add :amount_paid, :decimal, precision: 10, scale: 2, default: 0
      add :currency, :string, default: "USD", null: false

      # Dates
      add :invoice_date, :utc_datetime, null: false
      add :due_date, :utc_datetime
      add :paid_at, :utc_datetime

      # Payment provider details
      add :payment_provider, :string
      add :payment_provider_invoice_id, :string  # Stripe invoice ID (in_xxx)
      add :payment_provider_charge_id, :string  # Stripe charge ID (ch_xxx)
      add :hosted_invoice_url, :string  # URL to view invoice

      # Line items stored as JSON array
      add :line_items, {:array, :map}, default: []

      # Tax and discounts
      add :subtotal, :decimal, precision: 10, scale: 2
      add :tax_amount, :decimal, precision: 10, scale: 2, default: 0
      add :discount_amount, :decimal, precision: 10, scale: 2, default: 0

      # PDF storage
      add :pdf_url, :string

      timestamps()
    end

    # Create coupon codes table
    create table(:coupon_codes, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :code, :string, null: false
      add :name, :string
      add :description, :string

      # Discount type
      add :discount_type, :string, null: false  # "percentage", "fixed_amount"
      add :discount_value, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "USD"  # Only for fixed_amount

      # Duration
      add :duration, :string, null: false  # "once", "repeating", "forever"
      add :duration_months, :integer  # For "repeating" duration

      # Restrictions
      add :max_redemptions, :integer
      add :redemptions_count, :integer, default: 0, null: false
      add :valid_from, :utc_datetime
      add :valid_until, :utc_datetime
      add :applies_to_plans, {:array, :uuid}, default: []  # Empty = all plans

      # Status
      add :is_active, :boolean, default: true, null: false

      # Stripe details
      add :stripe_coupon_id, :string

      timestamps()
    end

    # Create user_coupons table for tracking coupon usage
    create table(:user_coupons, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :coupon_code_id, references(:coupon_codes, type: :uuid, on_delete: :delete_all), null: false
      add :user_subscription_id, references(:user_subscriptions, type: :uuid, on_delete: :nilify_all)

      add :applied_at, :utc_datetime, null: false
      add :expires_at, :utc_datetime  # For "repeating" coupons
      add :remaining_months, :integer  # For "repeating" coupons

      timestamps()
    end

    # Add Stripe price IDs to subscription_plans
    alter table(:subscription_plans) do
      add :stripe_price_id_monthly, :string
      add :stripe_price_id_yearly, :string
      add :stripe_product_id, :string
    end

    # Indexes
    create index(:payment_methods, [:user_id])
    create index(:payment_methods, [:payment_provider_customer_id])
    create unique_index(:payment_methods, [:payment_provider_method_id])
    create index(:payment_methods, [:is_default])

    create index(:invoices, [:user_id])
    create index(:invoices, [:user_subscription_id])
    create index(:invoices, [:status])
    create index(:invoices, [:invoice_date])
    create unique_index(:invoices, [:invoice_number])
    create unique_index(:invoices, [:payment_provider_invoice_id])

    create unique_index(:coupon_codes, [:code])
    create index(:coupon_codes, [:is_active])
    create index(:coupon_codes, [:valid_from, :valid_until])

    create unique_index(:user_coupons, [:user_id, :coupon_code_id])
    create index(:user_coupons, [:user_subscription_id])
  end
end
