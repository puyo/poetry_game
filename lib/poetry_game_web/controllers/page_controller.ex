defmodule PoetryGameWeb.PageController do
  use PoetryGameWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
