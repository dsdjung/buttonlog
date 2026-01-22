defmodule ButtonLogWeb.AdminLive.Dashboard do
  use ButtonLogWeb, :live_view

  alias ButtonLog.Support

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      user = ButtonLog.Accounts.get_user(user_id)

      if user && user.is_admin do
        stats = Support.get_stats()

        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:stats, stats)
         |> assign(:page_title, "Admin Dashboard")}
      else
        {:ok,
         socket
         |> put_flash(:error, "Admin access required")
         |> redirect(to: ~p"/")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in")
       |> redirect(to: ~p"/auth/login")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <div class="py-6">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 class="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
          <p class="mt-1 text-sm text-gray-600">Welcome, <%= @current_user.display_name || @current_user.username %></p>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
          <!-- Stats Grid -->
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <!-- Open Tickets -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
                      <span class="text-2xl">📬</span>
                    </div>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Open Tickets</dt>
                      <dd class="text-3xl font-semibold text-gray-900"><%= @stats.open %></dd>
                    </dl>
                  </div>
                </div>
              </div>
              <div class="bg-gray-50 px-5 py-3">
                <a href={~p"/admin/support?status=open"} class="text-sm font-medium text-blue-600 hover:text-blue-500">
                  View all →
                </a>
              </div>
            </div>

            <!-- In Progress -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                      <span class="text-2xl">🔧</span>
                    </div>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">In Progress</dt>
                      <dd class="text-3xl font-semibold text-gray-900"><%= @stats.in_progress %></dd>
                    </dl>
                  </div>
                </div>
              </div>
              <div class="bg-gray-50 px-5 py-3">
                <a href={~p"/admin/support?status=in_progress"} class="text-sm font-medium text-blue-600 hover:text-blue-500">
                  View all →
                </a>
              </div>
            </div>

            <!-- Unassigned -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                      <span class="text-2xl">⚠️</span>
                    </div>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Unassigned</dt>
                      <dd class="text-3xl font-semibold text-gray-900"><%= @stats.unassigned %></dd>
                    </dl>
                  </div>
                </div>
              </div>
              <div class="bg-gray-50 px-5 py-3">
                <a href={~p"/admin/support?assigned=unassigned"} class="text-sm font-medium text-blue-600 hover:text-blue-500">
                  View all →
                </a>
              </div>
            </div>

            <!-- High Priority -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
                      <span class="text-2xl">🔥</span>
                    </div>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">High Priority</dt>
                      <dd class="text-3xl font-semibold text-gray-900"><%= @stats.high_priority %></dd>
                    </dl>
                  </div>
                </div>
              </div>
              <div class="bg-gray-50 px-5 py-3">
                <a href={~p"/admin/support?priority=high"} class="text-sm font-medium text-blue-600 hover:text-blue-500">
                  View all →
                </a>
              </div>
            </div>
          </div>

          <!-- Category Breakdown -->
          <div class="mt-8 bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Tickets by Category</h3>
              <div class="mt-5 grid grid-cols-2 gap-5 sm:grid-cols-4">
                <div class="text-center">
                  <span class="text-2xl">🐛</span>
                  <p class="mt-2 text-2xl font-semibold text-gray-900"><%= Map.get(@stats.by_category, "bug", 0) %></p>
                  <p class="text-sm text-gray-500">Bugs</p>
                </div>
                <div class="text-center">
                  <span class="text-2xl">💡</span>
                  <p class="mt-2 text-2xl font-semibold text-gray-900"><%= Map.get(@stats.by_category, "feature_request", 0) %></p>
                  <p class="text-sm text-gray-500">Features</p>
                </div>
                <div class="text-center">
                  <span class="text-2xl">❓</span>
                  <p class="mt-2 text-2xl font-semibold text-gray-900"><%= Map.get(@stats.by_category, "question", 0) %></p>
                  <p class="text-sm text-gray-500">Questions</p>
                </div>
                <div class="text-center">
                  <span class="text-2xl">📝</span>
                  <p class="mt-2 text-2xl font-semibold text-gray-900"><%= Map.get(@stats.by_category, "other", 0) %></p>
                  <p class="text-sm text-gray-500">Other</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Links -->
          <div class="mt-8 bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Quick Actions</h3>
              <div class="mt-5 flex flex-wrap gap-4">
                <a href={~p"/admin/support"} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700">
                  View All Tickets
                </a>
                <a href={~p"/"} class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50">
                  Back to App
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
