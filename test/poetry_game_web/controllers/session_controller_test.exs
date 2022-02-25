defmodule PoetryGameWeb.SessionControllerTest do
  use PoetryGameWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = post(conn, "/api/session", %{"user" => %{"name" => "Name", "color" => "Red"}})
    assert json_response(conn, 200) == "{}"
    assert get_session(conn, :user_name) == "Name"
    assert get_session(conn, :user_color) == "Red"
  end
end
