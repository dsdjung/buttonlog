defmodule ButtonLogWeb.AdminLive.Support do
  use ButtonLogWeb, :live_view

  alias ButtonLog.Support
  alias ButtonLog.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      user = Accounts.get_user(user_id)

      if user && user.is_admin do
        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:tickets, [])
         |> assign(:selected_ticket, nil)
         |> assign(:filters, %{})
         |> assign(:reply_content, "")
         |> assign(:reply_internal, false)
         |> assign(:page_title, "Support Tickets")}
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
  def handle_params(params, _uri, socket) do
    case socket.assigns.live_action do
      :index ->
        filters = build_filters(params)
        tickets = Support.list_all_tickets(filters)

        {:noreply,
         socket
         |> assign(:filters, filters)
         |> assign(:tickets, tickets)
         |> assign(:selected_ticket, nil)}

      :show ->
        ticket_id = params["id"]

        case Support.get_ticket_admin(ticket_id) do
          {:ok, ticket} ->
            {:noreply,
             socket
             |> assign(:selected_ticket, ticket)
             |> assign(:page_title, "Ticket: #{ticket.subject}")}

          {:error, :not_found} ->
            {:noreply,
             socket
             |> put_flash(:error, "Ticket not found")
             |> push_navigate(to: ~p"/admin/support")}
        end
    end
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    filters = build_filters(filter_params)
    {:noreply, push_patch(socket, to: build_filter_url(filters))}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/support")}
  end

  @impl true
  def handle_event("update_status", %{"status" => status}, socket) do
    ticket = socket.assigns.selected_ticket

    case Support.update_ticket_status(ticket.id, status) do
      {:ok, updated_ticket} ->
        # Notify user of status change
        Support.notify_ticket_status_update(updated_ticket.id, status)

        {:ok, ticket} = Support.get_ticket_admin(updated_ticket.id)

        {:noreply,
         socket
         |> assign(:selected_ticket, ticket)
         |> put_flash(:info, "Status updated to #{status}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update status")}
    end
  end

  @impl true
  def handle_event("update_priority", %{"priority" => priority}, socket) do
    ticket = socket.assigns.selected_ticket

    case Support.update_ticket_priority(ticket.id, priority) do
      {:ok, updated_ticket} ->
        {:ok, ticket} = Support.get_ticket_admin(updated_ticket.id)

        {:noreply,
         socket
         |> assign(:selected_ticket, ticket)
         |> put_flash(:info, "Priority updated to #{priority}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update priority")}
    end
  end

  @impl true
  def handle_event("assign_to_me", _params, socket) do
    ticket = socket.assigns.selected_ticket
    admin = socket.assigns.current_user

    case Support.assign_ticket(ticket.id, admin.id) do
      {:ok, updated_ticket} ->
        {:ok, ticket} = Support.get_ticket_admin(updated_ticket.id)

        {:noreply,
         socket
         |> assign(:selected_ticket, ticket)
         |> put_flash(:info, "Ticket assigned to you")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to assign ticket")}
    end
  end

  @impl true
  def handle_event("unassign", _params, socket) do
    ticket = socket.assigns.selected_ticket

    case Support.unassign_ticket(ticket.id) do
      {:ok, updated_ticket} ->
        {:ok, ticket} = Support.get_ticket_admin(updated_ticket.id)

        {:noreply,
         socket
         |> assign(:selected_ticket, ticket)
         |> put_flash(:info, "Ticket unassigned")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unassign ticket")}
    end
  end

  @impl true
  def handle_event("update_reply", %{"reply" => %{"content" => content}}, socket) do
    {:noreply, assign(socket, :reply_content, content)}
  end

  @impl true
  def handle_event("update_reply", %{"content" => content}, socket) do
    {:noreply, assign(socket, :reply_content, content)}
  end

  @impl true
  def handle_event("toggle_internal", _params, socket) do
    {:noreply, assign(socket, :reply_internal, !socket.assigns.reply_internal)}
  end

  @impl true
  def handle_event("send_reply", %{"reply" => %{"content" => content}}, socket) do
    do_send_reply(socket, content)
  end

  @impl true
  def handle_event("send_reply", _params, socket) do
    do_send_reply(socket, socket.assigns.reply_content)
  end

  defp do_send_reply(socket, content) do
    ticket = socket.assigns.selected_ticket
    admin = socket.assigns.current_user
    is_internal = socket.assigns.reply_internal

    if String.trim(content || "") == "" do
      {:noreply, put_flash(socket, :error, "Reply cannot be empty")}
    else
      case Support.add_message(ticket.id, content, admin.id, is_internal: is_internal) do
        {:ok, _message} ->
          # Notify user only for non-internal messages
          unless is_internal do
            Support.notify_ticket_reply(ticket.id, admin.id)
          end

          {:ok, updated_ticket} = Support.get_ticket_admin(ticket.id)

          {:noreply,
           socket
           |> assign(:selected_ticket, updated_ticket)
           |> assign(:reply_content, "")
           |> assign(:reply_internal, false)
           |> put_flash(:info, if(is_internal, do: "Internal note added", else: "Reply sent"))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to send reply")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <div class="py-6">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-gray-900">Support Tickets</h1>
              <p class="mt-1 text-sm text-gray-600">
                <a href={~p"/admin"} class="text-blue-600 hover:underline">← Back to Dashboard</a>
              </p>
            </div>
          </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
          <%= if @selected_ticket do %>
            <!-- Ticket Detail View -->
            <.ticket_detail ticket={@selected_ticket} current_user={@current_user} reply_content={@reply_content} reply_internal={@reply_internal} />
          <% else %>
            <!-- Filters -->
            <.filters filters={@filters} />

            <!-- Ticket List -->
            <.ticket_list tickets={@tickets} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp filters(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg mb-6">
      <div class="px-4 py-5 sm:p-6">
        <form phx-change="filter" phx-submit="filter">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Status</label>
              <select name="filters[status]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                <option value="">All Statuses</option>
                <option value="open" selected={@filters[:status] == "open"}>Open</option>
                <option value="in_progress" selected={@filters[:status] == "in_progress"}>In Progress</option>
                <option value="resolved" selected={@filters[:status] == "resolved"}>Resolved</option>
                <option value="closed" selected={@filters[:status] == "closed"}>Closed</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Category</label>
              <select name="filters[category]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                <option value="">All Categories</option>
                <option value="bug" selected={@filters[:category] == "bug"}>Bug</option>
                <option value="feature_request" selected={@filters[:category] == "feature_request"}>Feature Request</option>
                <option value="question" selected={@filters[:category] == "question"}>Question</option>
                <option value="other" selected={@filters[:category] == "other"}>Other</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Priority</label>
              <select name="filters[priority]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                <option value="">All Priorities</option>
                <option value="low" selected={@filters[:priority] == "low"}>Low</option>
                <option value="normal" selected={@filters[:priority] == "normal"}>Normal</option>
                <option value="high" selected={@filters[:priority] == "high"}>High</option>
                <option value="urgent" selected={@filters[:priority] == "urgent"}>Urgent</option>
              </select>
            </div>

            <div class="flex items-end">
              <button type="button" phx-click="clear_filters" class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                Clear Filters
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp ticket_list(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg overflow-hidden">
      <%= if Enum.empty?(@tickets) do %>
        <div class="px-4 py-12 text-center text-gray-500">
          <span class="text-4xl">📭</span>
          <p class="mt-4">No tickets found</p>
        </div>
      <% else %>
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ticket</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Assigned</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for ticket <- @tickets do %>
              <tr class="hover:bg-gray-50 cursor-pointer" phx-click={JS.navigate(~p"/admin/support/#{ticket.id}")}>
                <td class="px-6 py-4">
                  <div class="flex items-center">
                    <span class="mr-2"><%= category_icon(ticket.category) %></span>
                    <div>
                      <div class="text-sm font-medium text-gray-900"><%= ticket.subject %></div>
                      <div class="text-sm text-gray-500"><%= ticket.category %></div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900"><%= ticket.user.display_name || ticket.user.username %></div>
                  <div class="text-sm text-gray-500"><%= ticket.user.email %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_color(ticket.status)}"}>
                    <%= ticket.status %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{priority_color(ticket.priority)}"}>
                    <%= ticket.priority %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= if ticket.assigned_admin do %>
                    <%= ticket.assigned_admin.display_name || ticket.assigned_admin.username %>
                  <% else %>
                    <span class="text-red-500">Unassigned</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= Calendar.strftime(ticket.inserted_at, "%b %d, %Y") %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp ticket_detail(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Back button -->
      <a href={~p"/admin/support"} class="inline-flex items-center text-sm text-blue-600 hover:underline">
        ← Back to list
      </a>

      <!-- Ticket Header -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="flex items-start justify-between">
            <div>
              <div class="flex items-center space-x-2">
                <span class="text-2xl"><%= category_icon(@ticket.category) %></span>
                <h2 class="text-xl font-semibold text-gray-900"><%= @ticket.subject %></h2>
              </div>
              <p class="mt-1 text-sm text-gray-500">
                From: <%= @ticket.user.display_name || @ticket.user.username %> (<%= @ticket.user.email %>)
              </p>
              <p class="text-sm text-gray-500">
                Created: <%= Calendar.strftime(@ticket.inserted_at, "%B %d, %Y at %I:%M %p") %>
              </p>
            </div>

            <div class="flex flex-col items-end space-y-2">
              <span class={"px-3 py-1 text-sm font-semibold rounded-full #{status_color(@ticket.status)}"}>
                <%= @ticket.status %>
              </span>
              <span class={"px-3 py-1 text-sm font-semibold rounded-full #{priority_color(@ticket.priority)}"}>
                <%= @ticket.priority %>
              </span>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="mt-6 flex flex-wrap gap-4">
            <div>
              <label class="block text-xs font-medium text-gray-500">Status</label>
              <select phx-change="update_status" name="status" class="mt-1 rounded-md border-gray-300 text-sm">
                <option value="open" selected={@ticket.status == "open"}>Open</option>
                <option value="in_progress" selected={@ticket.status == "in_progress"}>In Progress</option>
                <option value="resolved" selected={@ticket.status == "resolved"}>Resolved</option>
                <option value="closed" selected={@ticket.status == "closed"}>Closed</option>
              </select>
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-500">Priority</label>
              <select phx-change="update_priority" name="priority" class="mt-1 rounded-md border-gray-300 text-sm">
                <option value="low" selected={@ticket.priority == "low"}>Low</option>
                <option value="normal" selected={@ticket.priority == "normal"}>Normal</option>
                <option value="high" selected={@ticket.priority == "high"}>High</option>
                <option value="urgent" selected={@ticket.priority == "urgent"}>Urgent</option>
              </select>
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-500">Assignment</label>
              <div class="mt-1 flex items-center space-x-2">
                <%= if @ticket.assigned_admin do %>
                  <span class="text-sm text-gray-700">
                    <%= @ticket.assigned_admin.display_name || @ticket.assigned_admin.username %>
                  </span>
                  <button phx-click="unassign" class="text-xs text-red-600 hover:underline">Unassign</button>
                <% else %>
                  <button phx-click="assign_to_me" class="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700">
                    Assign to me
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Messages -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Conversation</h3>

          <div class="space-y-4 max-h-96 overflow-y-auto">
            <%= for message <- @ticket.messages || [] do %>
              <div class={"p-4 rounded-lg #{message_bg_class(message, @ticket.user_id)}"}>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm font-medium text-gray-900">
                    <%= if message.sender do %>
                      <%= message.sender.display_name || message.sender.username %>
                      <%= if message.sender.is_admin do %>
                        <span class="ml-1 text-xs bg-blue-100 text-blue-800 px-1 rounded">Admin</span>
                      <% end %>
                    <% else %>
                      Unknown
                    <% end %>
                  </span>
                  <span class="text-xs text-gray-500">
                    <%= Calendar.strftime(message.inserted_at, "%b %d, %Y %I:%M %p") %>
                  </span>
                </div>
                <%= if message.is_internal do %>
                  <span class="text-xs bg-yellow-200 text-yellow-800 px-2 py-0.5 rounded mb-2 inline-block">Internal Note</span>
                <% end %>
                <p class="text-sm text-gray-700 whitespace-pre-wrap"><%= message.content %></p>
              </div>
            <% end %>
          </div>

          <!-- Reply Form -->
          <div class="mt-6 border-t pt-4">
            <h4 class="text-sm font-medium text-gray-900 mb-2">Reply</h4>
            <form phx-submit="send_reply" phx-change="update_reply">
              <textarea
                name="reply[content]"
                rows="4"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                placeholder="Type your reply..."
                phx-debounce="300"
              ><%= @reply_content %></textarea>

              <div class="mt-3 flex items-center justify-between">
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    checked={@reply_internal}
                    phx-click="toggle_internal"
                    class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span class="ml-2 text-sm text-gray-600">Internal note (not visible to user)</span>
                </label>

                <button
                  type="submit"
                  class={"px-4 py-2 text-sm font-medium text-white rounded-md #{if @reply_internal, do: "bg-yellow-600 hover:bg-yellow-700", else: "bg-blue-600 hover:bg-blue-700"}"}
                >
                  <%= if @reply_internal, do: "Add Internal Note", else: "Send Reply" %>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  defp build_filters(params) do
    params
    |> Map.take(["status", "category", "priority", "search"])
    |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
  end

  defp build_filter_url(filters) do
    query =
      filters
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")

    if query == "", do: ~p"/admin/support", else: "/admin/support?#{query}"
  end

  defp category_icon("bug"), do: "🐛"
  defp category_icon("feature_request"), do: "💡"
  defp category_icon("question"), do: "❓"
  defp category_icon(_), do: "📝"

  defp status_color("open"), do: "bg-yellow-100 text-yellow-800"
  defp status_color("in_progress"), do: "bg-blue-100 text-blue-800"
  defp status_color("resolved"), do: "bg-green-100 text-green-800"
  defp status_color("closed"), do: "bg-gray-100 text-gray-800"
  defp status_color(_), do: "bg-gray-100 text-gray-800"

  defp priority_color("low"), do: "bg-gray-100 text-gray-800"
  defp priority_color("normal"), do: "bg-blue-100 text-blue-800"
  defp priority_color("high"), do: "bg-orange-100 text-orange-800"
  defp priority_color("urgent"), do: "bg-red-100 text-red-800"
  defp priority_color(_), do: "bg-gray-100 text-gray-800"

  defp message_bg_class(message, ticket_user_id) do
    cond do
      message.is_internal -> "bg-yellow-50 border border-yellow-200"
      message.sender_id == ticket_user_id -> "bg-gray-100"
      true -> "bg-blue-50"
    end
  end
end
