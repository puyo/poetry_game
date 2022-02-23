defmodule PoetryGameWeb.GameLiveTest do
  use PoetryGameWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "first mount" do
    test "displays something", %{conn: conn} do
      user = %{id: "user_id", color: 0, name: "user_name"}

      assert {:ok, view, _html} =
               live_isolated(conn, PoetryGameWeb.Live.GameLive,
                 session: %{"id" => "1", "user" => user}
               )

      assert view
             |> element("#game_1")
             |> render_hook("resize", %{width: 800, height: 1000}) =~
               "Waiting for 2 more players"
    end
  end
end
