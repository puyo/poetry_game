defmodule PoetryGameWeb.GameController do
  use PoetryGameWeb, :controller

  # alias PoetryGame.{Db, Games}

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
    # game = Games.get_game!(id)
    render(conn, "show.html", id: id)
  end
end
