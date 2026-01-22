defmodule ButtonLog.Subscriptions.Invoice do
  @moduledoc """
  Schema for billing invoices.

  Invoices track payment history and are synced with Stripe invoices.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:draft, :open, :paid, :void, :uncollectible]

  schema "invoices" do
    field :invoice_number, :string
    field :status, Ecto.Enum, values: @statuses
    field :amount_due, :decimal
    field :amount_paid, :decimal, default: Decimal.new(0)
    field :currency, :string, default: "USD"

    # Dates
    field :invoice_date, :utc_datetime
    field :due_date, :utc_datetime
    field :paid_at, :utc_datetime

    # Payment provider
    field :payment_provider, :string
    field :payment_provider_invoice_id, :string
    field :payment_provider_charge_id, :string
    field :hosted_invoice_url, :string

    # Line items
    field :line_items, {:array, :map}, default: []

    # Amounts
    field :subtotal, :decimal
    field :tax_amount, :decimal, default: Decimal.new(0)
    field :discount_amount, :decimal, default: Decimal.new(0)

    # PDF
    field :pdf_url, :string

    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :user_subscription, ButtonLog.Subscriptions.UserSubscription

    timestamps()
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :user_id, :user_subscription_id, :invoice_number, :status,
      :amount_due, :amount_paid, :currency, :invoice_date, :due_date,
      :paid_at, :payment_provider, :payment_provider_invoice_id,
      :payment_provider_charge_id, :hosted_invoice_url, :line_items,
      :subtotal, :tax_amount, :discount_amount, :pdf_url
    ])
    |> validate_required([:user_id, :invoice_number, :status, :amount_due, :invoice_date])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:amount_due, greater_than_or_equal_to: 0)
    |> validate_number(:amount_paid, greater_than_or_equal_to: 0)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "CAD", "AUD"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:user_subscription_id)
    |> unique_constraint(:invoice_number)
    |> unique_constraint(:payment_provider_invoice_id)
  end

  @doc """
  Returns true if the invoice is paid.
  """
  def paid?(%__MODULE__{status: :paid}), do: true
  def paid?(_), do: false

  @doc """
  Returns true if the invoice is overdue.
  """
  def overdue?(%__MODULE__{status: status, due_date: due_date}) when status in [:open, :draft] do
    case due_date do
      nil -> false
      due -> DateTime.compare(DateTime.utc_now(), due) == :gt
    end
  end

  def overdue?(_), do: false

  @doc """
  Returns the remaining balance on the invoice.
  """
  def balance(%__MODULE__{amount_due: due, amount_paid: paid}) do
    Decimal.sub(due, paid)
  end

  @doc """
  Generates a unique invoice number.
  """
  def generate_invoice_number do
    date_part = DateTime.utc_now() |> Calendar.strftime("%Y%m%d")
    random_part = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "INV-#{date_part}-#{random_part}"
  end
end
