defmodule ButtonLog.Support.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @categories ~w(bug feature_request question other)
  @priorities ~w(low normal high urgent)
  @statuses ~w(open in_progress resolved closed)

  schema "support_tickets" do
    field :subject, :string
    field :category, :string
    field :priority, :string, default: "normal"
    field :status, :string, default: "open"

    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :assigned_admin, ButtonLog.Accounts.User
    has_many :messages, ButtonLog.Support.TicketMessage

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:subject, :category, :priority, :status, :user_id, :assigned_admin_id])
    |> validate_required([:subject, :category])
    |> validate_length(:subject, min: 1, max: 200)
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:priority, @priorities)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:assigned_admin_id)
  end

  def create_changeset(ticket, attrs, user_id) do
    ticket
    |> cast(attrs, [:subject, :category, :priority])
    |> put_change(:user_id, user_id)
    |> put_change(:status, "open")
    |> validate_required([:subject, :category, :user_id])
    |> validate_length(:subject, min: 1, max: 200)
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:priority, @priorities)
    |> foreign_key_constraint(:user_id)
  end

  def update_status_changeset(ticket, status) do
    ticket
    |> change(status: status)
    |> validate_inclusion(:status, @statuses)
  end

  def assign_changeset(ticket, admin_id) do
    ticket
    |> change(assigned_admin_id: admin_id)
    |> foreign_key_constraint(:assigned_admin_id)
  end

  def categories, do: @categories
  def priorities, do: @priorities
  def statuses, do: @statuses
end
