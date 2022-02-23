defmodule PoetryGameWeb.GameLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  test "successfully gets ready to start the game", %{conn: conn} do
    game_id = "1"
    user1 = %{id: "1", color: 1, name: "user1"}
    user2 = %{id: "2", color: 2, name: "user2"}
    user3 = %{id: "3", color: 3, name: "user3"}

    assert {:ok, view1, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user1}
             )

    assert render_hook(view1, "resize", %{width: 800, height: 1000}) =~
             "Waiting for 2 more players"

    assert {:ok, view2, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user2}
             )

    assert render_hook(view2, "resize", %{width: 800, height: 1000}) =~
             "Waiting for 1 more player"

    assert render(view1) =~ "Waiting for 1 more player"

    assert {:ok, view3, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user3}
             )

    assert render_hook(view3, "resize", %{width: 800, height: 1000}) =~
             "Waiting for 0 more players"

    assert render(view1) =~ "Waiting for 0 more players"
    assert render(view2) =~ "Waiting for 0 more players"

    assert view1 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
    assert view2 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
    assert view3 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
  end

  test "the bug?", %{conn: conn} do
    game_id = "1"
    user1 = %{id: "1", color: 1, name: "user1"}
    user2 = %{id: "2", color: 2, name: "user2"}
    user3 = %{id: "3", color: 3, name: "user3"}

    assert {:ok, view1, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user1}
             )

    assert {:ok, view2, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user2}
             )

    assert {:ok, view3, _html} =
             live_isolated(conn, PoetryGameWeb.Live.GameLive,
               session: %{"id" => game_id, "user" => user3}
             )

    assert view1 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
    assert view2 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
    assert view3 |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
  end
end
