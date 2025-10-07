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
    <div class="min-h-screen bg-gradient-to-br from-purple-900 via-purple-700 to-purple-500">
      <div class="w-full">
        <!-- Header Section -->
        <div class="bg-gradient-to-r from-purple-800 to-purple-600 shadow-2xl">
          <div class="w-full px-8 py-8">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
              <div class="flex-1">
                <h1 class="text-5xl md:text-6xl font-black text-white mb-2 tracking-tight">
                  🏆 Leaderboard
                </h1>
                <p class="text-purple-200 text-lg">Compete with the best players worldwide</p>
              </div>
              <div class="flex flex-wrap gap-3">
                <a
                  href="/game"
                  class="px-6 py-3 bg-white/20 backdrop-blur-sm text-white rounded-xl hover:bg-white/30 transition-all duration-300 font-semibold shadow-lg hover:shadow-xl hover:scale-105"
                >
                  ← Back to Game
                </a>
                <%= if !@anonymous do %>
                  <a
                    href="/logout"
                    class="px-6 py-3 bg-purple-900/50 backdrop-blur-sm text-white rounded-xl hover:bg-purple-900/70 transition-all duration-300 font-semibold shadow-lg"
                  >
                    Logout
                  </a>
                <% end %>
              </div>
            </div>

            <!-- User Info Card -->
            <div class="mt-6 p-5 bg-white/10 backdrop-blur-md rounded-2xl border border-white/20 shadow-xl">
              <%= if @anonymous do %>
                <p class="text-white text-lg">
                  🎭 <span class="font-bold">Playing as Anonymous</span>
                  - <a href="/login" class="text-purple-200 hover:text-white underline decoration-2 underline-offset-4">
                    Login
                  </a>
                  to claim your spot on the leaderboard!
                </p>
              <% else %>
                <p class="text-white text-lg">
                  👤 <span class="font-bold text-purple-200">Logged in as:</span>
                  <span class="font-black"><%= @current_user.email %></span>
                </p>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Filter Section -->
        <div class="w-full px-8 py-8">
          <div class="bg-white/95 backdrop-blur-lg rounded-3xl shadow-2xl p-8 border border-purple-200">
            <h2 class="text-3xl font-black text-purple-900 mb-6 flex items-center gap-3">
              <span class="text-4xl">📊</span>
              Filter Leaderboard
            </h2>

            <div class="flex flex-col lg:flex-row gap-6">
              <!-- Level Filter -->
              <div class="flex-1">
                <label class="block text-sm font-bold text-purple-900 mb-3 uppercase tracking-wide">
                  Select Level
                </label>
                <form phx-change="filter_level">
                  <select
                    name="level_id"
                    class="w-full px-5 py-4 border-2 border-purple-300 rounded-xl focus:outline-none focus:ring-4 focus:ring-purple-500 focus:border-purple-500 bg-white text-gray-900 font-semibold shadow-sm hover:shadow-md transition-all cursor-pointer"
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
                    "px-8 py-4 rounded-xl font-bold text-lg transition-all duration-300 shadow-lg hover:shadow-2xl hover:scale-105 transform",
                    if(@filter_type == :global,
                      do: "bg-gradient-to-r from-purple-600 to-purple-800 text-white ring-4 ring-purple-300",
                      else: "bg-purple-100 text-purple-900 hover:bg-purple-200"
                    )
                  ]}
                >
                  🌍 Global Rankings
                </button>
              </div>
            </div>

            <!-- Filter Status -->
            <div class="mt-6 p-4 bg-purple-50 rounded-xl border-l-4 border-purple-600">
              <%= if @filter_type == :level do %>
                <p class="text-purple-900 font-semibold">
                  <span class="text-purple-600">●</span> Showing top scores for
                  <span class="font-black text-purple-700">
                    <%= Enum.find(@levels, &(&1.id == @selected_level_id))
                      |> then(fn level -> level && level.name end) || "Unknown Level" %>
                  </span>
                </p>
              <% else %>
                <p class="text-purple-900 font-semibold">
                  <span class="text-purple-600">●</span> Showing global rankings across all levels
                </p>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Leaderboard Table -->
        <div class="w-full px-8 pb-8">
          <div class="bg-white/95 backdrop-blur-lg rounded-3xl shadow-2xl overflow-hidden border border-purple-200">
            <%= if @filter_type == :level do %>
              <%= render_level_leaderboard(assigns) %>
            <% else %>
              <%= render_global_leaderboard(assigns) %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_level_leaderboard(assigns) do
    ~H"""
    <div>
      <div class="bg-gradient-to-r from-purple-600 via-purple-700 to-purple-800 px-8 py-6">
        <h2 class="text-3xl font-black text-white flex items-center gap-3">
          <span class="text-4xl">🎮</span>
          Level Leaderboard
        </h2>
      </div>

      <%= if Enum.empty?(@leaderboard_data) do %>
        <div class="p-20 text-center">
          <div class="text-8xl mb-6">🏁</div>
          <p class="text-2xl font-bold text-purple-900 mb-2">No scores yet for this level!</p>
          <p class="text-lg text-purple-600">Be the first champion to complete it!</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gradient-to-r from-purple-100 to-purple-200">
              <tr>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Rank
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Player
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Time
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Moves
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Completed
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-purple-100">
              <%= for {score, index} <- Enum.with_index(@leaderboard_data, 1) do %>
                <tr class={[
                  "hover:bg-purple-50 transition-all duration-200",
                  if(score.user_id == (@current_user && @current_user.id),
                    do: "bg-purple-100 font-bold shadow-inner",
                    else: ""
                  ),
                  if(index <= 3, do: "bg-gradient-to-r from-yellow-50 via-amber-50 to-orange-50", else: "")
                ]}>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-3">
                      <span class="text-4xl drop-shadow-lg">
                        <%= rank_emoji(index) %>
                      </span>
                      <span class={[
                        "text-2xl font-black",
                        if(index <= 3, do: "text-amber-600", else: "text-purple-700")
                      ]}>
                        #<%= index %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center">
                      <div>
                        <div class="text-lg font-bold text-gray-900">
                          <%= score.user.email %>
                          <%= if score.user_id == (@current_user && @current_user.id) do %>
                            <span class="ml-3 px-3 py-1 bg-purple-600 text-white text-xs font-black rounded-full uppercase">
                              You
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <span class="text-2xl">⏱️</span>
                      <span class="text-lg font-bold text-purple-900">
                        <%= format_time(score.time_seconds) %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <span class="text-2xl">🚶</span>
                      <span class="text-lg font-bold text-purple-900">
                        <%= score.moves %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap text-sm text-purple-600 font-semibold">
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
      <div class="bg-gradient-to-r from-purple-800 via-purple-600 to-purple-700 px-8 py-6">
        <h2 class="text-3xl font-black text-white flex items-center gap-3">
          <span class="text-4xl">🌍</span>
          Global Rankings
        </h2>
        <p class="text-purple-200 mt-2 text-lg font-semibold">
          Ranked by unique levels completed and average performance
        </p>
      </div>

      <%= if Enum.empty?(@leaderboard_data) do %>
        <div class="p-20 text-center">
          <div class="text-8xl mb-6">🌟</div>
          <p class="text-2xl font-bold text-purple-900 mb-2">No global scores yet!</p>
          <p class="text-lg text-purple-600">Complete some levels to climb the global ranks!</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gradient-to-r from-purple-100 to-purple-200">
              <tr>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Rank
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Player
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Levels Completed
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Avg Time
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Avg Moves
                </th>
                <th class="px-8 py-5 text-left text-sm font-black text-purple-900 uppercase tracking-wider">
                  Best Time
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-purple-100">
              <%= for {stats, index} <- Enum.with_index(@leaderboard_data, 1) do %>
                <tr class={[
                  "hover:bg-purple-50 transition-all duration-200",
                  if(stats.user_id == (@current_user && @current_user.id),
                    do: "bg-purple-100 font-bold shadow-inner",
                    else: ""
                  ),
                  if(index <= 3, do: "bg-gradient-to-r from-yellow-50 via-amber-50 to-orange-50", else: "")
                ]}>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-3">
                      <span class="text-4xl drop-shadow-lg">
                        <%= rank_emoji(index) %>
                      </span>
                      <span class={[
                        "text-2xl font-black",
                        if(index <= 3, do: "text-amber-600", else: "text-purple-700")
                      ]}>
                        #<%= index %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="text-lg font-bold text-gray-900">
                      <%= if stats.user do %>
                        <%= stats.user.email %>
                        <%= if stats.user_id == (@current_user && @current_user.id) do %>
                          <span class="ml-3 px-3 py-1 bg-purple-600 text-white text-xs font-black rounded-full uppercase">
                            You
                          </span>
                        <% end %>
                      <% else %>
                        <span class="text-gray-400">Unknown User</span>
                      <% end %>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="space-y-1">
                      <div class="flex items-center gap-2">
                        <span class="text-2xl">🎯</span>
                        <span class="text-xl font-black text-purple-700">
                          <%= stats.unique_levels %>
                        </span>
                        <span class="text-sm font-bold text-purple-600">levels</span>
                      </div>
                      <div class="text-xs text-purple-500 font-semibold pl-8">
                        <%= stats.total_completions %> total plays
                      </div>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <span class="text-2xl">⏱️</span>
                      <span class="text-lg font-bold text-purple-900">
                        <%= format_time(round(stats.avg_time || 0)) %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <span class="text-2xl">🚶</span>
                      <span class="text-lg font-bold text-purple-900">
                        <%= round(stats.avg_moves || 0) %>
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-5 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <span class="text-2xl">⚡</span>
                      <span class="text-lg font-bold text-purple-900">
                        <%= format_time(stats.best_time) %>
                      </span>
                    </div>
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
