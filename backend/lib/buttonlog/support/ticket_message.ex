defmodule ButtonLog.Support.TicketMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ticket_messages" do
    field :content, :string
    field :is_internal, :boolean, default: false
    field :read_at, :utc_datetime

    belongs_to :ticket, ButtonLog.Support.Ticket
    belongs_to :sender, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :is_internal, :read_at, :ticket_id, :sender_id])
    |> validate_required([:content])
    |> validate_length(:content, min: 1, max: 10_000)
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:sender_id)
  end

  def create_changeset(message, attrs, ticket_id, sender_id, opts \\ []) do
    is_internal = Keyword.get(opts, :is_internal, false)

    message
    |> cast(attrs, [:content])
    |> put_change(:ticket_id, ticket_id)
    |> put_change(:sender_id, sender_id)
    |> put_change(:is_internal, is_internal)
    |> validate_required([:content, :ticket_id, :sender_id])
    |> validate_length(:content, min: 1, max: 10_000)
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:sender_id)
  end

  def mark_read_changeset(message) do
    message
    |> change(read_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
