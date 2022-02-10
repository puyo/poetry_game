defmodule PoetryGame.Db.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :uuid}

  schema "games" do
    field :uuid, Ecto.UUID
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  @doc false
  def changeset(%__MODULE__{} = game, attrs) do
    game
    |> cast(attrs, [:uuid])
  end
end
