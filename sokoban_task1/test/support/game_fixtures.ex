defmodule SokobanTask1.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SokobanTask1.Game` context.
  """

  alias SokobanTask1.Game

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    Game.new_level()
  end
end
