defmodule ButtonLog.Subscriptions.UserCoupon do
  @moduledoc """
  Schema for tracking coupon usage by users.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_coupons" do
    field :applied_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :remaining_months, :integer

    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :coupon_code, ButtonLog.Subscriptions.CouponCode
    belongs_to :user_subscription, ButtonLog.Subscriptions.UserSubscription

    timestamps()
  end

  @doc false
  def changeset(user_coupon, attrs) do
    user_coupon
    |> cast(attrs, [
      :user_id, :coupon_code_id, :user_subscription_id,
      :applied_at, :expires_at, :remaining_months
    ])
    |> validate_required([:user_id, :coupon_code_id, :applied_at])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:coupon_code_id)
    |> foreign_key_constraint(:user_subscription_id)
    |> unique_constraint([:user_id, :coupon_code_id])
  end

  @doc """
  Returns true if the user coupon is still active.
  """
  def active?(%__MODULE__{expires_at: nil}), do: true

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end

  @doc """
  Returns true if the coupon has remaining uses (for repeating coupons).
  """
  def has_remaining_uses?(%__MODULE__{remaining_months: nil}), do: true
  def has_remaining_uses?(%__MODULE__{remaining_months: months}), do: months > 0

  @doc """
  Decrements the remaining months for a repeating coupon.
  """
  def decrement_remaining(%__MODULE__{remaining_months: nil} = coupon), do: coupon
  def decrement_remaining(%__MODULE__{remaining_months: months} = coupon) do
    %{coupon | remaining_months: max(0, months - 1)}
  end
end
