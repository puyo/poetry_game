defmodule PoetryGame.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add(:uuid, :uuid, null: false, default: fragment("uuid_generate_v1()"))
      add(:created_at, :timestamp, null: false, default: fragment("CURRENT_TIMESTAMP"))
      add(:updated_at, :timestamp, null: false, default: fragment("CURRENT_TIMESTAMP"))
    end
  end
end
