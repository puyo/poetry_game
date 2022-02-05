defmodule PoetryGame.Db.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :state, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end
