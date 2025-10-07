defmodule SokobanTask1Web.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true
  attr :kind, :atom, values: [:info, :error], default: :info

  def flash_group(assigns) do
    ~H"""
    <div class="flash-group">
      <%= for {kind, msg} <- @flash do %>
        <div class={[
          "alert",
          kind == :info && "alert-info",
          kind == :error && "alert-error"
        ]}>
          <%= msg %>
        </div>
      <% end %>
    </div>
    """
  end
end
