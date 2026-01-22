defmodule ButtonLog.Buttons.AutoStopWorker do
  @moduledoc """
  A periodic worker that processes auto-stop for toggle buttons.

  This GenServer runs every minute and checks for buttons that have
  scheduled_stop_at times that have passed, automatically stopping them.
  """

  use GenServer
  require Logger

  @check_interval :timer.minutes(1)  # Check every minute

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first check
    schedule_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_auto_stops, state) do
    process_auto_stops()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_auto_stops, @check_interval)
  end

  defp process_auto_stops do
    {:ok, count} = ButtonLog.Buttons.process_all_auto_stops()

    if count > 0 do
      Logger.info("AutoStopWorker: Processed #{count} auto-stop(s)")
    end
  end
end
