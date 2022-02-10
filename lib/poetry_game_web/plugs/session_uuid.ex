defmodule PoetryGameWeb.Plugs.SessionUuid do
  def init(opts), do: opts

  def call(conn, _opts) do
    Plug.Conn.put_session(
      conn,
      :user_id,
      Plug.Conn.get_session(conn, :user_id) || Ecto.UUID.generate()
    )
  end
end
