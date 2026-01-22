defmodule ButtonLog.Subscriptions.PaymentMethod do
  @moduledoc """
  Schema for storing user payment methods.

  Payment methods are linked to payment providers (Stripe) and store
  card details for display purposes. The actual payment method ID
  is used for charging.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payment_methods" do
    field :payment_provider, :string
    field :payment_provider_method_id, :string
    field :payment_provider_customer_id, :string

    # Card display details
    field :card_brand, :string
    field :card_last_four, :string
    field :card_exp_month, :integer
    field :card_exp_year, :integer

    # Status
    field :is_default, :boolean, default: false
    field :is_active, :boolean, default: true

    # Billing info
    field :billing_name, :string
    field :billing_email, :string
    field :billing_address, :map

    belongs_to :user, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [
      :user_id, :payment_provider, :payment_provider_method_id,
      :payment_provider_customer_id, :card_brand, :card_last_four,
      :card_exp_month, :card_exp_year, :is_default, :is_active,
      :billing_name, :billing_email, :billing_address
    ])
    |> validate_required([:user_id, :payment_provider, :payment_provider_method_id])
    |> validate_inclusion(:payment_provider, ["stripe"])
    |> validate_length(:card_last_four, is: 4)
    |> validate_inclusion(:card_exp_month, 1..12)
    |> validate_number(:card_exp_year, greater_than_or_equal_to: DateTime.utc_now().year)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:payment_provider_method_id)
  end

  @doc """
  Returns whether the payment method is expired.
  """
  def expired?(%__MODULE__{card_exp_month: month, card_exp_year: year}) when is_integer(month) and is_integer(year) do
    now = DateTime.utc_now()
    current_year = now.year
    current_month = now.month

    year < current_year or (year == current_year and month < current_month)
  end

  def expired?(_), do: false

  @doc """
  Returns a display string for the card (e.g., "Visa ****1234").
  """
  def display_string(%__MODULE__{card_brand: brand, card_last_four: last_four}) do
    brand_display = brand |> to_string() |> String.capitalize()
    "#{brand_display} ****#{last_four}"
  end

  @doc """
  Returns the expiration date as a string (e.g., "12/2025").
  """
  def expiration_string(%__MODULE__{card_exp_month: month, card_exp_year: year}) when is_integer(month) and is_integer(year) do
    month_str = month |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{month_str}/#{year}"
  end

  def expiration_string(_), do: nil
end
