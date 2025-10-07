defmodule SokobanTask1Web.RegisterLive do
  use SokobanTask1Web, :live_view

  alias SokobanTask1.Accounts
  alias SokobanTask1.Accounts.User

  def mount(_params, _session, socket) do
    changeset = User.registration_changeset(%User{}, %{}, hash_password: false)

    {:ok,
     socket
     |> assign(:form, to_form(changeset, as: "user"))
     |> assign(:check_errors, false)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> User.registration_changeset(user_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"), check_errors: true)}
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully! Please log in.")
         |> redirect(to: "/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"), check_errors: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br  py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8 bg-white/95 backdrop-blur-lg rounded-3xl shadow-2xl p-8 border border-purple-200">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Create your account
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Join us and start playing!
          </p>
        </div>

        <.form
          for={@form}
          phx-change="validate"
          phx-submit="register"
          class="mt-8 space-y-6"
        >
          <div class="rounded-md shadow-sm space-y-4">
            <div>
              <label for="user_email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <input
                id="user_email"
                name="user[email]"
                type="email"
                required
                class="mt-1 appearance-none relative block w-full px-3 py-2 border-2 border-purple-300 placeholder-gray-500 text-gray-900 rounded-xl focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm"
                placeholder="you@example.com"
                value={@form[:email].value || ""}
              />
              <%= if @check_errors && @form[:email].errors != [] do %>
                <%= for {msg, _opts} <- @form[:email].errors do %>
                  <p class="mt-1 text-sm text-red-600"><%= msg %></p>
                <% end %>
              <% end %>
            </div>

            <div>
              <label for="user_password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <input
                id="user_password"
                name="user[password]"
                type="password"
                required
                class="mt-1 appearance-none relative block w-full px-3 py-2 border-2 border-purple-300 placeholder-gray-500 text-gray-900 rounded-xl focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm"
                placeholder="At least 6 characters"
              />
              <%= if @check_errors && @form[:password].errors != [] do %>
                <%= for {msg, _opts} <- @form[:password].errors do %>
                  <p class="mt-1 text-sm text-red-600"><%= msg %></p>
                <% end %>
              <% end %>
            </div>

            <div>
              <label for="user_role" class="block text-sm font-medium text-gray-700">
                Role
              </label>
              <select
                id="user_role"
                name="user[role]"
                class="mt-1 block w-full px-3 py-2 border-2 border-purple-300 bg-white rounded-xl shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm"
              >
                <option value="user" selected={@form[:role].value == "user" || @form[:role].value == nil}>User</option>
                <option value="admin" selected={@form[:role].value == "admin"}>Admin</option>
              </select>
              <p class="mt-1 text-xs text-gray-500">
                Choose 'Admin' only if you need administrative privileges
              </p>
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-bold rounded-xl text-white bg-gradient-to-r from-purple-600 to-purple-800 hover:shadow-2xl hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-300"
            >
              ✨ Create Account
            </button>
          </div>
        </.form>

        <div class="text-center">
          <a href="/login" class="font-bold text-purple-600 hover:text-purple-800 transition-colors">
            Already have an account? Sign in →
          </a>
        </div>
      </div>
    </div>
    """
  end
end
