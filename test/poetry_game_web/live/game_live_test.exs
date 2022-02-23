defmodule PoetryGameWeb.GameLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  alias PoetryGameWeb.Presence

  describe "first mount" do
    test "displays something", %{conn: conn} do
      user1 = %{id: "1", color: 1, name: "user1"}
      user2 = %{id: "2", color: 2, name: "user2"}
      user3 = %{id: "3", color: 3, name: "user3"}

      assert {:ok, view, _html} =
               live_isolated(conn, PoetryGameWeb.Live.GameLive,
                 session: %{"id" => "1", "user" => user1}
               )

      assert render_hook(view, "resize", %{width: 800, height: 1000}) =~
               "Waiting for 2 more players"

      Presence.track(self(), "game:1", user2.id, user2)

      PoetryGame.GameServer.game("1")
      |> IO.inspect()

      assert render(view) =~ "Waiting for 1 more player"

      Presence.track(self(), "game:1", user3.id, user3)

      assert render(view) =~ "Waiting for 0 more players"

      PoetryGame.GameServer.game("1")
      |> IO.inspect()

      assert view |> element("button.start-game:not([disabled])") |> render() =~ "Start Game"
    end
  end
end
