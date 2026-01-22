defmodule ButtonLog.Subscriptions.CouponCode do
  @moduledoc """
  Schema for coupon/promo codes.

  Supports percentage and fixed amount discounts with various duration options.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @discount_types [:percentage, :fixed_amount]
  @durations [:once, :repeating, :forever]

  schema "coupon_codes" do
    field :code, :string
    field :name, :string
    field :description, :string

    # Discount
    field :discount_type, Ecto.Enum, values: @discount_types
    field :discount_value, :decimal
    field :currency, :string, default: "USD"

    # Duration
    field :duration, Ecto.Enum, values: @durations
    field :duration_months, :integer

    # Restrictions
    field :max_redemptions, :integer
    field :redemptions_count, :integer, default: 0
    field :valid_from, :utc_datetime
    field :valid_until, :utc_datetime
    field :applies_to_plans, {:array, :binary_id}, default: []

    # Status
    field :is_active, :boolean, default: true

    # Stripe
    field :stripe_coupon_id, :string

    has_many :user_coupons, ButtonLog.Subscriptions.UserCoupon

    timestamps()
  end

  @doc false
  def changeset(coupon_code, attrs) do
    coupon_code
    |> cast(attrs, [
      :code, :name, :description, :discount_type, :discount_value,
      :currency, :duration, :duration_months, :max_redemptions,
      :redemptions_count, :valid_from, :valid_until, :applies_to_plans,
      :is_active, :stripe_coupon_id
    ])
    |> validate_required([:code, :discount_type, :discount_value, :duration])
    |> validate_inclusion(:discount_type, @discount_types)
    |> validate_inclusion(:duration, @durations)
    |> validate_number(:discount_value, greater_than: 0)
    |> validate_percentage()
    |> validate_duration_months()
    |> validate_dates()
    |> upcase_code()
    |> unique_constraint(:code)
  end

  defp validate_percentage(changeset) do
    case get_field(changeset, :discount_type) do
      :percentage ->
        validate_number(changeset, :discount_value, less_than_or_equal_to: 100)

      _ ->
        changeset
    end
  end

  defp validate_duration_months(changeset) do
    case get_field(changeset, :duration) do
      :repeating ->
        changeset
        |> validate_required([:duration_months])
        |> validate_number(:duration_months, greater_than: 0)

      _ ->
        changeset
    end
  end

  defp validate_dates(changeset) do
    valid_from = get_field(changeset, :valid_from)
    valid_until = get_field(changeset, :valid_until)

    case {valid_from, valid_until} do
      {from, until} when not is_nil(from) and not is_nil(until) ->
        if DateTime.compare(from, until) == :gt do
          add_error(changeset, :valid_until, "must be after valid_from")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp upcase_code(changeset) do
    case get_change(changeset, :code) do
      nil -> changeset
      code -> put_change(changeset, :code, String.upcase(code))
    end
  end

  @doc """
  Returns true if the coupon is currently valid for redemption.
  """
  def valid?(%__MODULE__{is_active: false}), do: false

  def valid?(%__MODULE__{} = coupon) do
    now = DateTime.utc_now()

    within_dates?(coupon, now) and within_redemption_limit?(coupon)
  end

  defp within_dates?(coupon, now) do
    from_ok =
      case coupon.valid_from do
        nil -> true
        from -> DateTime.compare(now, from) != :lt
      end

    until_ok =
      case coupon.valid_until do
        nil -> true
        until_date -> DateTime.compare(now, until_date) != :gt
      end

    from_ok and until_ok
  end

  defp within_redemption_limit?(coupon) do
    case coupon.max_redemptions do
      nil -> true
      max -> coupon.redemptions_count < max
    end
  end

  @doc """
  Calculates the discount amount for a given price.
  """
  def calculate_discount(%__MODULE__{discount_type: :percentage, discount_value: value}, price) do
    Decimal.mult(price, Decimal.div(value, 100))
  end

  def calculate_discount(%__MODULE__{discount_type: :fixed_amount, discount_value: value}, _price) do
    value
  end

  @doc """
  Returns the discount as a display string.
  """
  def discount_display(%__MODULE__{discount_type: :percentage, discount_value: value}) do
    "#{Decimal.to_string(value)}% off"
  end

  def discount_display(%__MODULE__{discount_type: :fixed_amount, discount_value: value, currency: currency}) do
    "$#{Decimal.to_string(value)} #{currency} off"
  end
end
