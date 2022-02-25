defmodule PoetryGameWeb.SessionController do
  use PoetryGameWeb, :controller

  def set(conn, %{"user" => %{"name" => name, "color" => color}}) do
    conn
    |> put_session(:user_name, name)
    |> put_session(:user_color, color)
    |> json("{}")
  end
end
