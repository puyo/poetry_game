defmodule PoetryGameWeb.RouterTest do
  use PoetryGameWeb.ConnCase, async: true

  test "GET /dashboard/home", %{conn: conn} do
    conn = get(conn, "/dashboard/home")
    assert html_response(conn, 200)
  end

  test "GET /dashboard/metrics", %{conn: conn} do
    conn = get(conn, "/dashboard/metrics?nav=phoenix")
    assert html_response(conn, 200)
  end
end
