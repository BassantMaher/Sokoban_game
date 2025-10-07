defmodule SokobanTask1Web.LeaderboardLive do
  use SokobanTask1Web, :live_view

  alias SokobanTask1.{Scores, Levels}

  @impl true
  def mount(_params, session, socket) do
    # Get current user
    current_user = get_current_user(socket, session)
    is_anonymous = socket.assigns[:anonymous] || session["anonymous"] || false

    # Load all levels for filter dropdown
    levels = Levels.list_levels()
    
    # Default to first level
    selected_level_id = if level = List.first(levels), do: level.id, else: nil
    
    # Load leaderboard data
    leaderboard_data = load_leaderboard_data(selected_level_id, :level)

    socket =
      socket
      |> assign(:page_title, "Leaderboard")
      |> assign(:current_user, current_user)
      |> assign(:anonymous, is_anonymous)
      |> assign(:levels, levels)
      |> assign(:selected_level_id, selected_level_id)
      |> assign(:filter_type, :level)
      |> assign(:leaderboard_data, leaderboard_data)

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_level", %{"level_id" => level_id_str}, socket) do
    level_id = String.to_integer(level_id_str)
    leaderboard_data = load_leaderboard_data(level_id, :level)

    {:noreply,
     socket
     |> assign(:selected_level_id, level_id)
     |> assign(:filter_type, :level)
     |> assign(:leaderboard_data, leaderboard_data)}
  end

  @impl true
  def handle_event("filter_global", _params, socket) do
    leaderboard_data = load_leaderboard_data(nil, :global)

    {:noreply,
     socket
     |> assign(:filter_type, :global)
     |> assign(:leaderboard_data, leaderboard_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-50 to-blue-100 py-8 px-4">
      <div class="max-w-6xl mx-auto">
        <!-- Header -->
        <div class="bg-white rounded-lg shadow-xl p-6 mb-6">
          <div class="flex justify-between items-center mb-4">
            <div>
              <h1 class="text-4xl font-bold text-gray-800">🏆 Leaderboard</h1>
              <p class="text-gray-600 mt-2">Top players and high scores</p>
            </div>
            <div class="flex gap-4">
              <a
                href="/game"
                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition"
              >
                ← Back to Game
              </a>
              <%= if !@anonymous do %>
                <a href="/logout" class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition">
                  Logout
                </a>
              <% end %>
            </div>
          </div>

          <!-- User Info -->
          <div class="mt-4 p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg">
            <%= if @anonymous do %>
              <p class="text-gray-700">
                🎭 <span class="font-semibold">Playing as Anonymous</span>
                - <a href="/login" class="text-blue-600 hover:underline">Login</a> to see your rank!
              </p>
            <% else %>
              <p class="text-gray-700">
                👤 Logged in as: <span class="font-semibold"><%= @current_user.email %></span>
              </p>
            <% end %>
          </div>
        </div>

        <!-- Filter Options -->
        <div class="bg-white rounded-lg shadow-xl p-6 mb-6">
          <h2 class="text-2xl font-bold text-gray-800 mb-4">📊 Filter Leaderboard</h2>
          
          <div class="flex flex-wrap gap-4">
            <!-- Level Filter -->
            <div class="flex-1 min-w-[300px]">
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Filter by Level
              </label>
              <form phx-change="filter_level">
                <select
                  name="level_id"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  <%= for level <- @levels do %>
                    <option value={level.id} selected={level.id == @selected_level_id}>
                      Level <%= level.order %>: <%= level.name %> (<%= String.capitalize(to_string(level.difficulty)) %>)
                    </option>
                  <% end %>
                </select>
              </form>
            </div>

            <!-- Global Filter Button -->
            <div class="flex items-end">
              <button
                phx-click="filter_global"
                class={[
                  "px-6 py-2 rounded-lg font-semibold transition",
                  if(@filter_type == :global,
                    do: "bg-purple-600 text-white",
                    else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                  )
                ]}
              >
                🌍 Global Leaderboard
              </button>
            </div>
          </div>

          <!-- Filter Info -->
          <div class="mt-4 text-sm text-gray-600">
            <%= if @filter_type == :level do %>
              <p>
                Showing top scores for
                <span class="font-semibold">
                  <%= Enum.find(@levels, &(&1.id == @selected_level_id))
                    |> then(fn level -> level && level.name end) || "Unknown Level" %>
                </span>
              </p>
            <% else %>
              <p>Showing global rankings across all levels</p>
            <% end %>
          </div>
        </div>

        <!-- Leaderboard Table -->
        <div class="bg-white rounded-lg shadow-xl overflow-hidden">
          <%= if @filter_type == :level do %>
            <%= render_level_leaderboard(assigns) %>
          <% else %>
            <%= render_global_leaderboard(assigns) %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_level_leaderboard(assigns) do
    ~H"""
    <div>
      <div class="bg-gradient-to-r from-purple-600 to-blue-600 px-6 py-4">
        <h2 class="text-2xl font-bold text-white">
          🎮 Level Leaderboard
        </h2>
      </div>

      <%= if Enum.empty?(@leaderboard_data) do %>
        <div class="p-12 text-center text-gray-500">
          <p class="text-xl">No scores yet for this level!</p>
          <p class="mt-2">Be the first to complete it!</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-100">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Rank
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Player
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Time
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Moves
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Completed
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {score, index} <- Enum.with_index(@leaderboard_data, 1) do %>
                <tr class={[
                  if(score.user_id == (@current_user && @current_user.id),
                    do: "bg-blue-50 font-semibold",
                    else: ""
                  ),
                  if(index <= 3, do: "bg-gradient-to-r from-yellow-50 to-orange-50", else: "")
                ]}>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="text-2xl">
                      <%= rank_emoji(index) %>
                    </span>
                    <span class="ml-2 text-lg font-bold">
                      <%= index %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div>
                        <div class="text-sm font-medium text-gray-900">
                          <%= score.user.email %>
                          <%= if score.user_id == (@current_user && @current_user.id) do %>
                            <span class="ml-2 text-xs text-blue-600">(You)</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900">
                      ⏱️ <%= format_time(score.time_seconds) %>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900">
                      🚶 <%= score.moves %>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= format_date(score.completed_at) %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_global_leaderboard(assigns) do
    ~H"""
    <div>
      <div class="bg-gradient-to-r from-green-600 to-teal-600 px-6 py-4">
        <h2 class="text-2xl font-bold text-white">
          🌍 Global Rankings
        </h2>
        <p class="text-sm text-green-100 mt-1">
          Ranked by unique levels completed and average performance
        </p>
      </div>

      <%= if Enum.empty?(@leaderboard_data) do %>
        <div class="p-12 text-center text-gray-500">
          <p class="text-xl">No global scores yet!</p>
          <p class="mt-2">Complete some levels to appear here!</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-100">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Rank
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Player
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Levels Completed
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Avg Time
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Avg Moves
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Best Time
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {stats, index} <- Enum.with_index(@leaderboard_data, 1) do %>
                <tr class={[
                  if(stats.user_id == (@current_user && @current_user.id),
                    do: "bg-blue-50 font-semibold",
                    else: ""
                  ),
                  if(index <= 3, do: "bg-gradient-to-r from-yellow-50 to-orange-50", else: "")
                ]}>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="text-2xl">
                      <%= rank_emoji(index) %>
                    </span>
                    <span class="ml-2 text-lg font-bold">
                      <%= index %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900">
                      <%= if stats.user do %>
                        <%= stats.user.email %>
                        <%= if stats.user_id == (@current_user && @current_user.id) do %>
                          <span class="ml-2 text-xs text-blue-600">(You)</span>
                        <% end %>
                      <% else %>
                        Unknown User
                      <% end %>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-bold text-green-600">
                      🎯 <%= stats.unique_levels %> levels
                    </div>
                    <div class="text-xs text-gray-500">
                      <%= stats.total_completions %> total plays
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    ⏱️ <%= format_time(round(stats.avg_time || 0)) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    🚶 <%= round(stats.avg_moves || 0) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    ⚡ <%= format_time(stats.best_time) %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions

  defp load_leaderboard_data(level_id, :level) when not is_nil(level_id) do
    Scores.get_leaderboard(level_id, 50)
  end

  defp load_leaderboard_data(_level_id, :level), do: []

  defp load_leaderboard_data(_level_id, :global) do
    Scores.get_global_leaderboard(50)
  end

  defp get_current_user(socket, session) do
    cond do
      socket.assigns[:current_user] != nil ->
        socket.assigns[:current_user]

      is_integer(session["user_id"]) ->
        case SokobanTask1.Accounts.get_user(session["user_id"]) do
          nil -> nil
          user -> user
        end

      true ->
        nil
    end
  end

  defp rank_emoji(1), do: "🥇"
  defp rank_emoji(2), do: "🥈"
  defp rank_emoji(3), do: "🥉"
  defp rank_emoji(_), do: "🎖️"

  defp format_time(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  defp format_time(_), do: "0:00"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
