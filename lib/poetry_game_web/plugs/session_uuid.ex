defmodule PoetryGameWeb.Plugs.SessionUuid do
  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = Plug.Conn.get_session(conn, :user_id) || Ecto.UUID.generate()
    user_name = Plug.Conn.get_session(conn, :user_name) || "anon"

    conn
    |> Plug.Conn.put_session(:user_id, user_id)
    |> Plug.Conn.put_session(:user_name, user_name)
  end
end
