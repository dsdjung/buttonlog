defmodule ButtonLogWeb.TestLive do
  use ButtonLogWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    IO.puts "=== TEST LIVEVIEW MOUNT ==="
    {:ok, assign(socket, :message, "Hello from Test LiveView!")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold">Test LiveView</h1>
      <p class="mt-4"><%= @message %></p>
      <button phx-click="test_click" class="mt-4 bg-blue-500 text-white px-4 py-2 rounded">
        Test Click
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("test_click", _params, socket) do
    IO.puts "=== TEST CLICK EVENT ==="
    {:noreply, assign(socket, :message, "Button clicked!")}
  end
end

