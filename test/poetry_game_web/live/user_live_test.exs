defmodule PoetryGameWeb.UserLiveTest do
  use PoetryGameWeb.ConnCase, async: true

  import Mock
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
           |> render_click() =~ "Color"

    assert view1
           |> render_change("change", %{user: %{name: "NAME2", color: "4"}}) =~ "NAME2"

    assert view1
           |> render_hook("submit", %{user: %{name: "UPDATED", color: "2"}}) =~ "UPDATED"

    assert view1
           |> element("button.show-user-form")
           |> render_click() =~ "Color"

    refute view1
           |> element(".modal-close")
           |> render_click() =~ "Color"
  end

  test_with_mock "with an error during mount",
                 %{conn: conn},
                 PoetryGameWeb.Endpoint,
                 [:passthrough],
                 subscribe: fn _topic -> {:error, "error subscribing"} end do
    game_id = "1"
    user1 = %{id: "1", color: 1, name: "user1"}

    assert {:ok, _view1, _html} =
             live_isolated(conn, PoetryGameWeb.Live.UserLive,
               session: %{"game_id" => game_id, "user" => user1}
             )
  end
end
