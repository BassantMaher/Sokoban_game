defmodule SokobanTask1Web.AuthHTML do
  @moduledoc """
  This module contains pages rendered by AuthController.
  """
  use SokobanTask1Web, :html

  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag

  embed_templates "auth_html/*"

  @doc """
  Renders error tags for form fields.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "block text-xs text-red-300 mt-1"
      )
    end)
  end

  # Utility function for translating errors
  defp translate_error({msg, opts}) do
    # You can use gettext here if you want translations
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg), do: msg
end
