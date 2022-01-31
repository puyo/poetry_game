defmodule PoetryGame.Repo do
  use Ecto.Repo,
    otp_app: :poetry_game,
    adapter: Ecto.Adapters.Postgres
end
