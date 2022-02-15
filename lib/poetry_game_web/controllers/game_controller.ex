defmodule PoetryGameWeb.GameController do
  use PoetryGameWeb, :controller

  def index(conn, _params) do
    games = []
    render(conn, "index.html", games: games)
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    Routes.game_path(conn, :show, id: Ecto.UUID.generate())
  end

  def show(conn, %{"id" => id}) do
    user = %{
      id: get_session(conn, :user_id),
      color: get_session(conn, :user_color),
      name: get_session(conn, :user_name)
    }

    render(conn, "show.html", id: id, user: user)
  end
end
