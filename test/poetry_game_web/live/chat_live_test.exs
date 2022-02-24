defmodule PoetryGameWeb.ChatLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  test "successful chat", %{conn: conn} do
    game_id = "1"
    user1 = %{id: "1", color: 1, name: "user1"}
    user2 = %{id: "2", color: 2, name: "user2"}

    assert {:ok, view1, _html} =
             live_isolated(conn, PoetryGameWeb.Live.ChatLive,
               session: %{"game_id" => game_id, "user" => user1}
             )

    assert {:ok, view2, _html} =
             live_isolated(conn, PoetryGameWeb.Live.ChatLive,
               session: %{"game_id" => game_id, "user" => user2}
             )

    assert render(view1) =~ "user1"
    assert render(view1) =~ "user2"
    assert render(view2) =~ "user1"
    assert render(view2) =~ "user2"

    view1
    |> form("form", %{message: %{user_name: "user1", color: 1, content: "Hi there"}})
    |> render_submit()

    assert render(view1) =~ "Hi there"
    assert render(view2) =~ "Hi there"

    new_user = %{id: "1", color: 1, name: "UPDATED_NAME"}
    PoetryGameWeb.Endpoint.local_broadcast("user:all", "update_user", new_user)

    assert view1 |> render() =~ "UPDATED_NAME"
    assert view2 |> render() =~ "UPDATED_NAME"
  end
end
