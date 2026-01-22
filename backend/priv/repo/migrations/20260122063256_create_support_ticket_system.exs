defmodule ButtonLog.Repo.Migrations.CreateSupportTicketSystem do
  use Ecto.Migration

  def change do
    # Support tickets table
    create table(:support_tickets, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :subject, :string, null: false
      add :category, :string, null: false
      add :priority, :string, default: "normal"
      add :status, :string, default: "open"
      add :assigned_admin_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create index(:support_tickets, [:user_id])
    create index(:support_tickets, [:status])
    create index(:support_tickets, [:assigned_admin_id])
    create index(:support_tickets, [:category])
    create index(:support_tickets, [:priority])

    # Category constraint
    create constraint(:support_tickets, :valid_category,
      check: "category IN ('bug', 'feature_request', 'question', 'other')"
    )

    # Priority constraint
    create constraint(:support_tickets, :valid_priority,
      check: "priority IN ('low', 'normal', 'high', 'urgent')"
    )

    # Status constraint
    create constraint(:support_tickets, :valid_status,
      check: "status IN ('open', 'in_progress', 'resolved', 'closed')"
    )

    # Ticket messages table
    create table(:ticket_messages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :ticket_id, references(:support_tickets, type: :uuid, on_delete: :delete_all), null: false
      add :sender_id, references(:users, type: :uuid, on_delete: :nilify_all), null: false
      add :content, :text, null: false
      add :is_internal, :boolean, default: false
      add :read_at, :utc_datetime

      timestamps()
    end

    create index(:ticket_messages, [:ticket_id])
    create index(:ticket_messages, [:sender_id])
    create index(:ticket_messages, [:inserted_at])
  end
end
