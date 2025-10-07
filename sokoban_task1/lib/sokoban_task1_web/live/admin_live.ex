defmodule SokobanTask1Web.AdminLive do
  use SokobanTask1Web, :live_view

  alias SokobanTask1.{Levels, Levels.Level}

  @impl true
  def mount(_params, session, socket) do
    # Get current user
    current_user = get_current_user(socket, session)

    # Double-check admin (should be handled by plug, but good practice)
    if current_user && current_user.role == "admin" do
      # Load all existing levels
      levels = Levels.list_levels()
      next_order = Levels.get_next_level_order()

      # Create a changeset for the form
      changeset = Levels.change_level(%Level{order: next_order})

      socket =
        socket
        |> assign(:page_title, "Admin Panel")
        |> assign(:current_user, current_user)
        |> assign(:levels, levels)
        |> assign(:next_order, next_order)
        |> assign(:changeset, changeset)
        |> assign(:form, to_form(changeset))
        |> assign(:board_preview, nil)
        |> assign(:show_success, false)
        |> assign(:success_message, nil)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Unauthorized access")
       |> redirect(to: "/game")}
    end
  end

  @impl true
  def handle_event("validate", %{"level" => level_params}, socket) do
    # Parse board_data from textarea string to array
    level_params = parse_board_data(level_params)

    changeset =
      %Level{}
      |> Levels.change_level(level_params)
      |> Map.put(:action, :validate)

    board_preview = generate_board_preview(level_params["board_data"])

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:board_preview, board_preview)
     |> assign(:show_success, false)}
  end

  @impl true
  def handle_event("save", %{"level" => level_params}, socket) do
    # Parse board_data from textarea string to array
    level_params = parse_board_data(level_params)

    case Levels.create_level_with_order(level_params) do
      {:ok, level} ->
        # Reload levels and get next order
        levels = Levels.list_levels()
        next_order = Levels.get_next_level_order()
        changeset = Levels.change_level(%Level{order: next_order})

        {:noreply,
         socket
         |> assign(:levels, levels)
         |> assign(:next_order, next_order)
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))
         |> assign(:board_preview, nil)
         |> assign(:show_success, true)
         |> assign(:success_message, "Level \"#{level.name}\" created successfully! (Order: #{level.order})")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))
         |> assign(:show_success, false)}
    end
  end

  @impl true
  def handle_event("preview_board", %{"level" => level_params}, socket) do
    level_params = parse_board_data(level_params)
    board_preview = generate_board_preview(level_params["board_data"])

    {:noreply, assign(socket, :board_preview, board_preview)}
  end

  @impl true
  def handle_event("clear_form", _params, socket) do
    next_order = Levels.get_next_level_order()
    changeset = Levels.change_level(%Level{order: next_order})

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:board_preview, nil)
     |> assign(:show_success, false)
     |> assign(:next_order, next_order)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-900 via-purple-700 to-purple-500">
      <div class="w-full">
        <!-- Header -->
        <div class="bg-gradient-to-r from-purple-800 to-purple-600 shadow-2xl">
          <div class="w-full px-8 py-8">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
              <div class="flex-1">
                <h1 class="text-5xl md:text-6xl font-black text-white mb-2 tracking-tight flex items-center gap-4">
                  <span class="text-6xl">⚙️</span>
                  Admin Panel
                </h1>
                <p class="text-purple-200 text-lg">Create and manage game levels</p>
              </div>
              <div class="flex flex-wrap gap-3">
                <a
                  href="/game"
                  class="px-6 py-3 bg-white/20 backdrop-blur-sm text-white rounded-xl hover:bg-white/30 transition-all duration-300 font-semibold shadow-lg"
                >
                  🎮 Game
                </a>
                <a
                  href="/leaderboard"
                  class="px-6 py-3 bg-white/20 backdrop-blur-sm text-white rounded-xl hover:bg-white/30 transition-all duration-300 font-semibold shadow-lg"
                >
                  🏆 Leaderboard
                </a>
                <a
                  href="/logout"
                  class="px-6 py-3 bg-purple-900/50 backdrop-blur-sm text-white rounded-xl hover:bg-purple-900/70 transition-all duration-300 font-semibold shadow-lg"
                >
                  Logout
                </a>
              </div>
            </div>

            <!-- User Info -->
            <div class="mt-6 p-5 bg-white/10 backdrop-blur-md rounded-2xl border border-white/20 shadow-xl">
              <p class="text-white text-lg">
                👤 <span class="font-bold text-purple-200">Admin:</span>
                <span class="font-black"><%= @current_user.email %></span>
              </p>
            </div>
          </div>
        </div>

        <div class="w-full px-8 py-8">
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-8">
            <!-- Create Level Form -->
            <div class="bg-white/95 backdrop-blur-lg rounded-3xl shadow-2xl p-8 border border-purple-200">
              <h2 class="text-3xl font-black text-purple-900 mb-6 flex items-center gap-3">
                <span class="text-4xl">➕</span>
                Create New Level
              </h2>

              <!-- Success Message -->
              <%= if @show_success do %>
                <div class="mb-6 p-5 bg-green-50 border-l-4 border-green-500 rounded-lg animate-pulse">
                  <p class="text-green-800 font-bold flex items-center gap-2">
                    <span class="text-2xl">✅</span>
                    <%= @success_message %>
                  </p>
                </div>
              <% end %>

              <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
                <!-- Level Order (Auto-assigned) -->
                <div class="p-4 bg-purple-50 rounded-xl border-2 border-purple-200">
                  <label class="block text-sm font-black text-purple-900 mb-2 uppercase">
                    Level Order (Auto-assigned)
                  </label>
                  <div class="text-3xl font-black text-purple-700">
                    # <%= @next_order %>
                  </div>
                  <input type="hidden" name="level[order]" value={@next_order} />
                </div>

                <!-- Level Name -->
                <div>
                  <label class="block text-sm font-black text-purple-900 mb-2 uppercase">
                    Level Name *
                  </label>
                  <input
                    type="text"
                    name="level[name]"
                    value={@form[:name].value}
                    placeholder="e.g., The Great Challenge"
                    class="w-full px-4 py-3 border-2 border-purple-300 rounded-xl focus:ring-4 focus:ring-purple-500 focus:border-purple-500 font-semibold"
                    required
                  />
                  <%= if @form[:name].errors != [] do %>
                    <p class="mt-1 text-sm text-red-600">
                      <%= translate_error(@form[:name].errors |> List.first()) %>
                    </p>
                  <% end %>
                </div>

                <!-- Difficulty -->
                <div>
                  <label class="block text-sm font-black text-purple-900 mb-2 uppercase">
                    Difficulty *
                  </label>
                  <select
                    name="level[difficulty]"
                    class="w-full px-4 py-3 border-2 border-purple-300 rounded-xl focus:ring-4 focus:ring-purple-500 focus:border-purple-500 font-semibold"
                    required
                  >
                    <option value="">Select difficulty...</option>
                    <option value="easy" selected={@form[:difficulty].value == "easy"}>
                      Easy - Beginner Friendly
                    </option>
                    <option value="medium" selected={@form[:difficulty].value == "medium"}>
                      Medium - Moderate Challenge
                    </option>
                    <option value="hard" selected={@form[:difficulty].value == "hard"}>
                      Hard - Expert Level
                    </option>
                    <option value="expert" selected={@form[:difficulty].value == "expert"}>
                      Expert - Master Only
                    </option>
                  </select>
                  <%= if @form[:difficulty].errors != [] do %>
                    <p class="mt-1 text-sm text-red-600">
                      <%= translate_error(@form[:difficulty].errors |> List.first()) %>
                    </p>
                  <% end %>
                </div>

                <!-- Description -->
                <div>
                  <label class="block text-sm font-black text-purple-900 mb-2 uppercase">
                    Description (Optional)
                  </label>
                  <textarea
                    name="level[description]"
                    placeholder="Add a description or hint for this level..."
                    class="w-full px-4 py-3 border-2 border-purple-300 rounded-xl focus:ring-4 focus:ring-purple-500 focus:border-purple-500 font-semibold"
                    rows="3"
                  ><%= @form[:description].value %></textarea>
                </div>

                <!-- Board Data -->
                <div>
                  <label class="block text-sm font-black text-purple-900 mb-2 uppercase">
                    Board Data * (One row per line)
                  </label>
                  <p class="text-sm text-purple-600 mb-2">
                    Use: # = Wall, @ = Player, $ = Box, . = Goal, (space) = Empty
                  </p>
                  <textarea
                    name="level[board_data]"
                    placeholder={"#####\n#@$.#\n#####"}
                    class="w-full px-4 py-3 border-2 border-purple-300 rounded-xl focus:ring-4 focus:ring-purple-500 focus:border-purple-500 font-mono text-sm"
                    rows="10"
                    required
                  ><%= format_board_for_textarea(@form[:board_data].value) %></textarea>
                  <%= if @form[:board_data].errors != [] do %>
                    <p class="mt-1 text-sm text-red-600">
                      <%= translate_error(@form[:board_data].errors |> List.first()) %>
                    </p>
                  <% end %>
                </div>

                <!-- Action Buttons -->
                <div class="flex gap-4 pt-4">
                  <button
                    type="submit"
                    class="flex-1 px-6 py-4 bg-gradient-to-r from-purple-600 to-purple-800 text-white rounded-xl font-black text-lg hover:shadow-2xl hover:scale-105 transition-all duration-300"
                  >
                    💾 Create Level
                  </button>
                  <button
                    type="button"
                    phx-click="clear_form"
                    class="px-6 py-4 bg-purple-100 text-purple-900 rounded-xl font-bold hover:bg-purple-200 transition-all"
                  >
                    🗑️ Clear
                  </button>
                </div>
              </.form>

              <!-- Board Preview -->
              <%= if @board_preview do %>
                <div class="mt-8 p-6 bg-purple-50 rounded-xl border-2 border-purple-300">
                  <h3 class="text-xl font-black text-purple-900 mb-4">Board Preview:</h3>
                  <div class="bg-white p-4 rounded-lg overflow-auto">
                    <pre class="font-mono text-sm"><%= @board_preview %></pre>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Existing Levels List -->
            <div class="bg-white/95 backdrop-blur-lg rounded-3xl shadow-2xl p-8 border border-purple-200">
              <h2 class="text-3xl font-black text-purple-900 mb-6 flex items-center gap-3">
                <span class="text-4xl">📋</span>
                Existing Levels (<%= length(@levels) %>)
              </h2>

              <div class="space-y-4 max-h-[800px] overflow-y-auto">
                <%= for level <- @levels do %>
                  <div class="p-5 bg-gradient-to-r from-purple-50 to-purple-100 rounded-xl border-2 border-purple-200 hover:shadow-lg transition-all">
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1">
                        <div class="flex items-center gap-3 mb-2">
                          <span class="text-2xl font-black text-purple-700">
                            #<%= level.order %>
                          </span>
                          <h3 class="text-xl font-bold text-gray-900">
                            <%= level.name %>
                          </h3>
                        </div>
                        <div class="flex flex-wrap gap-2 items-center">
                          <span class={[
                            "px-3 py-1 rounded-full text-xs font-black uppercase",
                            difficulty_badge_class(level.difficulty)
                          ]}>
                            <%= level.difficulty %>
                          </span>
                          <span class="text-sm text-purple-600 font-semibold">
                            <%= board_size(level.board_data) %>
                          </span>
                        </div>
                        <%= if level.description do %>
                          <p class="mt-2 text-sm text-gray-600 italic">
                            <%= level.description %>
                          </p>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

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

  defp parse_board_data(%{"board_data" => board_string} = params) when is_binary(board_string) do
    board_array =
      board_string
      |> String.split("\n")
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(params, "board_data", board_array)
  end

  defp parse_board_data(params), do: params

  defp generate_board_preview(board_data) when is_list(board_data) do
    Enum.join(board_data, "\n")
  end

  defp generate_board_preview(_), do: nil

  defp difficulty_badge_class("easy"), do: "bg-green-200 text-green-800"
  defp difficulty_badge_class("medium"), do: "bg-yellow-200 text-yellow-800"
  defp difficulty_badge_class("hard"), do: "bg-orange-200 text-orange-800"
  defp difficulty_badge_class("expert"), do: "bg-red-200 text-red-800"
  defp difficulty_badge_class(_), do: "bg-gray-200 text-gray-800"

  defp board_size(board_data) when is_list(board_data) do
    rows = length(board_data)
    cols = Enum.max_by(board_data, &String.length/1) |> String.length()
    "#{rows}×#{cols}"
  end

  defp board_size(_), do: "Unknown"

  defp format_board_for_textarea(board_data) when is_list(board_data) do
    Enum.join(board_data, "\n")
  end

  defp format_board_for_textarea(_), do: ""

  defp translate_error({msg, _opts}), do: msg
  defp translate_error(msg) when is_binary(msg), do: msg
  defp translate_error(_), do: "Invalid value"
end
