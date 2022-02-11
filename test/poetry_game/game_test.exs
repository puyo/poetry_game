defmodule PoetryGame.GameTest do
  use ExUnit.Case, async: true

  alias PoetryGame.Game

  describe "start/1" do
    test "successfully" do
      game =
        demo_game()
        |> Game.start()

      assert length(Game.player_list(game)) == 3
    end
  end

  describe "add_member/2" do
    test "already added" do
      assert {:error, :already_added} =
               Game.init()
               |> Game.add_member(%{id: "1", name: "A", color: 1})
               |> Game.add_member(%{id: "1", name: "A", color: 1})
    end
  end

  describe "remove_member/2" do
    test "not found" do
      assert {:error, :not_found} =
               Game.init()
               |> Game.remove_member("1")
    end

    test "success" do
      game =
        Game.init()
        |> Game.add_member(%{id: "1", name: "A", color: 1})
        |> Game.remove_member("1")

      assert map_size(game.members) == 0
    end
  end

  describe "set_word/3" do
    test "success" do
      game =
        demo_game()
        |> Game.start()

      assert [
               %{papers: [%{word: nil}]},
               %{papers: [%{word: nil}]},
               %{papers: [%{word: nil}]}
             ] = game.seats

      game =
        game
        |> Game.set_word("1", "foo")

      assert [
               %{papers: []},
               %{papers: [%{word: nil}, %{word: "foo"}]},
               %{papers: [%{word: nil}]}
             ] = game.seats
    end
  end

  defp demo_game() do
    Game.init()
    |> Game.add_member(%{id: "1", name: "A", color: 1})
    |> Game.add_member(%{id: "2", name: "B", color: 2})
    |> Game.add_member(%{id: "3", name: "C", color: 3})
  end
end
