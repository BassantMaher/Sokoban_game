defmodule SokobanTask1Web.GameLiveTest do
  use SokobanTask1Web.ConnCase

  import Phoenix.LiveViewTest
  import SokobanTask1.GameFixtures

  test "displays game board", %{conn: conn} do
    {:ok, _index_live, html} = live(conn, ~p"/")

    assert html =~ "Sokoban Game"
    assert html =~ "Use WASD or Arrow Keys to move"
  end

  test "handles player movement", %{conn: conn} do
    {:ok, index_live, _html} = live(conn, ~p"/")

    # Test moving player
    assert index_live |> element("div[phx-hook='KeyboardListener']") |> has_element?()

    # Simulate a move event
    assert index_live |> render_hook("move", %{"direction" => "up"})
  end

  test "handles reset event", %{conn: conn} do
    {:ok, index_live, _html} = live(conn, ~p"/")

    # Test reset button
    assert index_live |> element("button", "Reset Level") |> render_click()
  end
end
