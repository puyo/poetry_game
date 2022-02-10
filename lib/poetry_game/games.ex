defmodule PoetryGame.Games do
  import Ecto.Query, warn: false

  alias PoetryGame.{Db, Repo}

  def all, do: Repo.all(Db.Game)
  def get_game!(uuid), do: Repo.get_by!(Db.Game, uuid: uuid)

  def create_game() do
    %Db.Game{}
    |> Db.Game.changeset(%{uuid: Ecto.UUID.generate()})
    |> Repo.insert()
  end

  def change_game(%Db.Game{} = game, attrs \\ %{}) do
    Db.Game.changeset(game, attrs)
  end
end
