defmodule PoetryGameWeb.GameController do
  use PoetryGameWeb, :controller

  def create(conn, _params) do
    redirect(conn, to: Routes.game_path(conn, :show, Ecto.UUID.generate()))
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
