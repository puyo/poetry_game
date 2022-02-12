defmodule PoetryGame.GameTest do
  use ExUnit.Case, async: true

  alias PoetryGame.Game

  describe "start/1" do
    test "successfully" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      assert length(Game.player_list(game)) == 3
    end
  end

  describe "add_member/2" do
    test "already added" do
      game = Game.init()
      {:ok, game} = Game.add_member(game, %{id: "1", name: "A", color: 1})
      assert {:ok, _} = Game.add_member(game, %{id: "1", name: "A", color: 1})
      assert map_size(game.members) == 1
    end
  end

  describe "remove_member/2" do
    test "not found" do
      game = Game.init()
      assert {:error, :not_found} = Game.remove_member(game, "1")
    end

    test "success" do
      game = Game.init()
      {:ok, game} = Game.add_member(game, %{id: "1", name: "A", color: 1})
      {:ok, game} = Game.remove_member(game, "1")
      assert map_size(game.members) == 0
    end
  end

  describe "set_word/3" do
    test "success" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)

      assert [
               %{papers: [%{word: nil}]},
               %{papers: [%{word: nil}]},
               %{papers: [%{word: nil}]}
             ] = game.seats

      {:ok, game} = Game.set_word(game, "1", "foo")

      assert [
               %{papers: []},
               %{papers: [%{word: nil}, %{word: "foo"}]},
               %{papers: [%{word: nil}]}
             ] = game.seats
    end
  end

  describe "set_question/3" do
    test "success" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)

      assert [
               %{papers: [%{question: nil}]},
               %{papers: [%{question: nil}]},
               %{papers: [%{question: nil}]}
             ] = game.seats

      {:ok, game} = Game.set_question(game, "1", "foo")

      assert [
               %{papers: []},
               %{papers: [%{question: nil}, %{question: "foo"}]},
               %{papers: [%{question: nil}]}
             ] = game.seats
    end
  end

  describe "set_poem/3" do
    test "success" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)

      assert [
               %{papers: [%{poem: nil}]},
               %{papers: [%{poem: nil}]},
               %{papers: [%{poem: nil}]}
             ] = game.seats

      {:ok, game} = Game.set_poem(game, "1", "foo")

      assert [
               %{papers: [%{poem: "foo"}]},
               %{papers: [%{poem: nil}]},
               %{papers: [%{poem: nil}]}
             ] = game.seats
    end
  end

  defp demo_game() do
    with game = Game.init(),
         {:ok, game} <- Game.add_member(game, %{id: "1", name: "A", color: 1}),
         {:ok, game} <- Game.add_member(game, %{id: "2", name: "B", color: 2}),
         {:ok, game} <- Game.add_member(game, %{id: "3", name: "C", color: 3}) do
      {:ok, game}
    end
  end
end
