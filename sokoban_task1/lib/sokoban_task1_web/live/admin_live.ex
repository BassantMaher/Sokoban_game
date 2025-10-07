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
        |> assign(:original_board, nil)
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

    # Store original board before padding
    original_board = level_params["board_data"]
    board_preview = generate_board_preview(original_board)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:board_preview, board_preview)
     |> assign(:original_board, original_board)
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
                  <div class="mb-2 space-y-1">
                    <p class="text-sm text-purple-600">
                      Use: # = Wall, @ = Player, $ = Box, . = Goal, (space) = Empty
                    </p>
                    <div class="flex items-center gap-2 text-xs bg-purple-50 border border-purple-200 rounded-lg p-2">
                      <span class="text-purple-700">💡 <strong>Auto-padding:</strong></span>
                      <span class="text-purple-600">
                        Rows shorter than the longest row will be automatically padded with walls (#) on the right
                      </span>
                    </div>
                  </div>
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
                <div class="mt-8 p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl border-2 border-purple-300 shadow-lg">
                  <h3 class="text-xl font-black text-purple-900 mb-4 flex items-center gap-2">
                    <span class="text-2xl">👁️</span>
                    Live Preview
                  </h3>

                  <!-- Padding Info -->
                  <%= if has_padding?(@original_board, @board_preview) do %>
                    <div class="mb-4 p-3 bg-yellow-50 border-l-4 border-yellow-500 rounded">
                      <p class="text-sm text-yellow-800 font-semibold flex items-center gap-2">
                        <span class="text-lg">⚠️</span>
                        Auto-padding applied: Some rows were extended with walls to match the longest row
                      </p>
                    </div>
                  <% end %>

                  <div class="bg-gradient-to-br from-gray-800 to-gray-900 p-6 rounded-lg overflow-auto flex justify-center items-center min-h-[200px]">
                    <%= render_board_preview(assigns) %>
                  </div>

                  <div class="mt-3 space-y-2">
                    <p class="text-sm text-purple-700 italic">
                      ℹ️ This is how players will see your level
                    </p>
                    <%= if has_padding?(@original_board, @board_preview) do %>
                      <p class="text-xs text-yellow-700 font-semibold">
                        💡 Note: Walls with slightly dimmed appearance indicate auto-padded areas
                      </p>
                    <% end %>
                  </div>

                  <!-- Debug Info -->
                  <details class="mt-4 text-xs">
                    <summary class="cursor-pointer text-purple-700 font-semibold hover:text-purple-900">
                      🔍 Debug: Board Data Structure
                    </summary>
                    <div class="mt-2 space-y-2">
                      <div>
                        <p class="font-bold text-purple-800">Original (before padding):</p>
                        <pre class="mt-1 p-3 bg-white rounded border border-purple-200 overflow-auto"><%= inspect(@original_board, pretty: true) %></pre>
                      </div>
                      <div>
                        <p class="font-bold text-purple-800">After padding:</p>
                        <pre class="mt-1 p-3 bg-white rounded border border-purple-200 overflow-auto"><%= inspect(@board_preview, pretty: true) %></pre>
                      </div>
                    </div>
                  </details>
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
      |> Enum.map(&to_string/1)  # Ensure all rows are strings, not atoms

    Map.put(params, "board_data", board_array)
  end

  defp parse_board_data(params), do: params

  defp generate_board_preview(board_data) when is_list(board_data) and length(board_data) > 0 do
    # Ensure all rows are strings
    normalized_data =
      board_data
      |> Enum.map(fn row ->
        cond do
          is_binary(row) -> row
          is_atom(row) -> Atom.to_string(row)
          true -> to_string(row)
        end
      end)

    # Pad rows to ensure consistent width (minimum 12 columns)
    normalize_board_width(normalized_data)
  end

  defp generate_board_preview(_), do: nil

  # Normalize board width by padding short rows with walls
  defp normalize_board_width(board_data) do
    # Find the maximum width, but at least 12
    max_width =
      board_data
      |> Enum.map(&String.length/1)
      |> Enum.max()
      |> max(12)

    # Pad each row to max_width
    Enum.map(board_data, fn row ->
      current_length = String.length(row)

      if current_length < max_width do
        # Pad with walls on the right
        padding = String.duplicate("#", max_width - current_length)
        row <> padding
      else
        row
      end
    end)
  end

  defp render_board_preview(assigns) do
    ~H"""
    <%= if @board_preview && is_list(@board_preview) do %>
      <div class="inline-block">
        <%= for {row, y} <- Enum.with_index(@board_preview) do %>
          <div class="flex">
            <%= for {cell, x} <- Enum.with_index(to_string(row) |> String.graphemes()) do %>
              <div class={get_preview_cell_classes(cell, x, y, @board_preview, @original_board)}>
                <%= cell_symbol(cell) %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% else %>
      <div class="text-center text-gray-400 py-8">
        <p class="text-lg">No preview available</p>
        <p class="text-sm mt-2">Start designing your level above</p>
      </div>
    <% end %>
    """
  end

  defp get_preview_cell_classes(cell, x, y, board, original_board) do
    base_classes = ["cell"]

    # Check if this position is a goal (by checking if there's a '.' in the board)
    is_goal = String.contains?(cell, ".") or
              (cell == " " && has_goal_at_position?(board, x, y))

    # Check if this cell is in the padded area
    is_padded = is_padded_cell?(x, y, original_board)

    # Determine the visual class based on content
    cell_class = case {cell, is_goal} do
      {"#", _} -> "wall"
      {"@", true} -> "player-on-goal"
      {"@", false} -> "player"
      {"$", true} -> "box-on-goal"
      {"$", false} -> "box"
      {".", _} -> "goal"
      {" ", true} -> "goal"
      {" ", false} -> "empty"
      _ -> "empty"
    end

    # Add padded class for visual indication
    padded_class = if is_padded && cell == "#", do: "padded-wall", else: nil

    Enum.reject(base_classes ++ [cell_class, padded_class], &is_nil/1)
    |> Enum.join(" ")
  end

  # Check if a cell is in the padded area (beyond original row length)
  defp is_padded_cell?(x, y, original_board) when is_list(original_board) do
    original_row = Enum.at(original_board, y)

    if original_row do
      original_length = String.length(to_string(original_row))
      x >= original_length
    else
      false
    end
  end

  defp is_padded_cell?(_x, _y, _original_board), do: false

  # Check if padding was applied
  defp has_padding?(original_board, padded_board) when is_list(original_board) and is_list(padded_board) do
    Enum.zip(original_board, padded_board)
    |> Enum.any?(fn {original, padded} ->
      String.length(to_string(original)) < String.length(to_string(padded))
    end)
  end

  defp has_padding?(_original, _padded), do: false

  defp has_goal_at_position?(_board, _x, _y), do: false

  defp cell_symbol("#"), do: ""
  defp cell_symbol("@"), do: ""
  defp cell_symbol("$"), do: ""
  defp cell_symbol("."), do: ""
  defp cell_symbol(" "), do: ""
  defp cell_symbol(_), do: ""

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
