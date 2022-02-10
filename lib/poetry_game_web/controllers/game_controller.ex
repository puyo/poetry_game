defmodule PoetryGameWeb.GameController do
  use PoetryGameWeb, :controller

  alias PoetryGame.{Db, Games}

  def index(conn, _params) do
    games = Games.all()
    render(conn, "index.html", games: games)
  end

  def new(conn, _params) do
    changeset = Games.change_game(%Db.Game{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, _params) do
    case Games.create_game(%{}) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created successfully.")
        |> redirect(to: Routes.game_path(conn, :show, game))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Games.get_game!(id)
    render(conn, "show.html", game: game)
  end
end
