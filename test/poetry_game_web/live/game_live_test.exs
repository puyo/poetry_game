defmodule PoetryGameWeb.GameLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected", %{conn: conn} do
    conn = get(conn, "/games/1")
    assert html_response(conn, 200) =~ "Connecting..."
  end

  test "successful game", %{conn: conn} do
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

    assert view1
           |> element("button.start-game")
           |> render_click()

    assert view1 |> render() =~ "Enter a word"
    assert view2 |> render() =~ "Enter a word"
    assert view3 |> render() =~ "Enter a word"

    # invalid word

    view1
    |> form(".submit-value", word: "")
    |> render_submit()

    assert view1
           |> element(".submit-value")
           |> render() =~ "Enter a word"

    # valid words

    view1
    |> form(".submit-value", word: "w1")
    |> render_submit()

    view2
    |> form(".submit-value", word: "w2")
    |> render_submit()

    view3
    |> form(".submit-value", word: "w3")
    |> render_submit()

    # invalid question

    view1
    |> form(".submit-value", question: "")
    |> render_submit()

    assert view1
           |> element(".submit-value")
           |> render() =~ "Enter a question"

    # valid questions

    view1
    |> form(".submit-value", question: "q1")
    |> render_submit()

    view2
    |> form(".submit-value", question: "q2")
    |> render_submit()

    view3
    |> form(".submit-value", question: "q3")
    |> render_submit()

    # invalid poem

    view1
    |> form(".submit-value", poem: "")
    |> render_submit()

    assert view1
           |> element(".submit-value")
           |> render() =~ "Write a poem using the word and question above"

    # valid poems

    view1
    |> form(".submit-value", poem: "p1")
    |> render_submit()

    view2
    |> form(".submit-value", poem: "p2")
    |> render_submit()

    view3
    |> form(".submit-value", poem: "p3")
    |> render_submit()

    # game is finished

    view1_html = view1 |> render()
    assert view1_html =~ "w1"
    assert view1_html =~ "q1"
    assert view1_html =~ "p1"
    assert view1_html =~ "w2"
    assert view1_html =~ "q2"
    assert view1_html =~ "p2"
    assert view1_html =~ "w3"
    assert view1_html =~ "q3"
    assert view1_html =~ "p3"
    assert view1_html =~ "Please copy your poems if you want to keep them."
    assert view1_html =~ "Start New Game"
  end

  test "updating user", %{conn: conn} do
    game_id = "2"
    user1 = %{id: "1", color: 1, name: "user1"}
    user2 = %{id: "2", color: 2, name: "user2"}
    user3 = %{id: "3", color: 3, name: "user3"}

    {:ok, view1, _html} =
      live_isolated(conn, PoetryGameWeb.Live.GameLive,
        session: %{"id" => game_id, "user" => user1}
      )

    {:ok, view2, _html} =
      live_isolated(conn, PoetryGameWeb.Live.GameLive,
        session: %{"id" => game_id, "user" => user2}
      )

    {:ok, view3, _html} =
      live_isolated(conn, PoetryGameWeb.Live.GameLive,
        session: %{"id" => game_id, "user" => user3}
      )

    render_hook(view1, "resize", %{width: 800, height: 1000})
    render_hook(view2, "resize", %{width: 800, height: 1000})
    render_hook(view3, "resize", %{width: 800, height: 1000})

    assert view1
           |> element("button.start-game")
           |> render_click()

    assert view1 |> render() =~ "user1"

    new_user = %{id: "1", color: 1, name: "UPDATED_NAME"}
    PoetryGameWeb.Endpoint.local_broadcast("user:all", "update_user", new_user)

    # not sure why this extra render is needed
    view1 |> render()

    assert view1 |> render() =~ "UPDATED_NAME"
  end
end
