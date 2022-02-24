defmodule PoetryGameWeb.GameControllerTest do
  use PoetryGameWeb.ConnCase, async: true

  describe "create/2" do
    test "success", %{conn: conn} do
      conn = post(conn, "/games")
      location = redirected_to(conn)
      assert location =~ "/games/"
      %{"uuid" => uuid} = Regex.named_captures(~r{/games/(?<uuid>.*)$}, location)
      assert {:ok, _} = Ecto.UUID.cast(uuid)
    end
  end
end
