defmodule PoetryGameWeb.UserLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  test "successful user form show and user update", %{conn: conn} do
    game_id = "1"
    user1 = %{id: "1", color: 1, name: "user1"}

    assert {:ok, view1, _html} =
             live_isolated(conn, PoetryGameWeb.Live.UserLive,
               session: %{"game_id" => game_id, "user" => user1}
             )

    refute view1 |> render() =~ "Color"

    assert view1
           |> element("button.show-user-form")
           |> render_click()

    assert view1 |> render() =~ "Color"

    view1
    |> render_hook("submit", %{user: %{name: "UPDATED", color: "2"}})

    assert view1 |> render() =~ "UPDATED"
  end
end
