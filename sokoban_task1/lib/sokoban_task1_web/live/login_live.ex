defmodule SokobanTask1Web.LoginLive do
  use SokobanTask1Web, :live_view

  alias SokobanTask1.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"email" => "", "password" => ""}, as: "user"))
     |> assign(:errors, [])}
  end

  def handle_event("login", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Redirect to a controller action that will set the session
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back, #{user.email}!")
         |> redirect(to: "/auth/login_user/#{user.id}")}

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> assign(:errors, ["Invalid email or password"])
         |> assign(:form, to_form(user_params, as: "user"))}
    end
  end

  def handle_event("play_anonymous", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Playing as anonymous user")
     |> redirect(to: "/auth/login_anonymous")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8 bg-white rounded-lg shadow-2xl p-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            🎮 Sokoban Game
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Sign in to your account or play as guest
          </p>
        </div>

        <%= if @errors != [] do %>
          <div class="rounded-md bg-red-50 p-4">
            <div class="flex">
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  <%= for error <- @errors do %>
                    <p><%= error %></p>
                  <% end %>
                </h3>
              </div>
            </div>
          </div>
        <% end %>

        <.form for={@form} phx-submit="login" class="mt-8 space-y-6">
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <label for="email" class="sr-only">Email address</label>
              <input
                id="email"
                name="user[email]"
                type="email"
                autocomplete="email"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={@form[:email].value}
              />
            </div>
            <div>
              <label for="password" class="sr-only">Password</label>
              <input
                id="password"
                name="user[password]"
                type="password"
                autocomplete="current-password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={@form[:password].value}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Sign in
            </button>
          </div>
        </.form>

        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-gray-300"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-white text-gray-500">Or</span>
          </div>
        </div>

        <button
          phx-click="play_anonymous"
          class="w-full flex justify-center py-2 px-4 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          🎭 Play as Anonymous
        </button>

        <div class="text-center">
          <a href="/register" class="font-medium text-indigo-600 hover:text-indigo-500">
            Don't have an account? Register here
          </a>
        </div>
      </div>
    </div>
    """
  end
end
