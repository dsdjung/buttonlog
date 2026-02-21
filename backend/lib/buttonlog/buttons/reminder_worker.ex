defmodule ButtonLog.Buttons.ReminderWorker do
  @moduledoc """
  A periodic worker that processes button reminders.

  This GenServer runs every 5 minutes and checks for buttons that have
  reminders enabled and are due for notification, sending push notifications
  to the button owners.
  """

  use GenServer
  require Logger

  @check_interval :timer.minutes(5)  # Check every 5 minutes

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first check
    schedule_check()
    Logger.info("ReminderWorker: Started")
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_reminders, state) do
    process_reminders()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_reminders, @check_interval)
  end

  defp process_reminders do
    {:ok, count} = ButtonLog.Buttons.process_all_reminders()

    if count > 0 do
      Logger.info("ReminderWorker: Sent #{count} reminder(s)")
    end
  end
end
