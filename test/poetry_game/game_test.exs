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

  describe "user_at_seat/2" do
    test "success" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      assert %{id: "1"} = Game.user_at_seat(game, 0)
      assert Game.user_at_seat(game, 10) == nil
    end
  end

  describe "add_member/2" do
    test "already added" do
      game = Game.init("game_id")
      {:ok, game} = Game.add_member(game, %{id: "1"})
      assert {:ok, _} = Game.add_member(game, %{id: "1"})
      assert map_size(game.members) == 1
    end
  end

  describe "remove_member/2" do
    test "not found" do
      game = Game.init("game_id")
      assert {:error, :not_found} = Game.remove_member(game, "1")
    end

    test "success" do
      game = Game.init("game_id")
      {:ok, game} = Game.add_member(game, %{id: "1"})
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

      {:ok, game} = Game.set_word(game, "1", "foo", "a")

      assert [
               %{papers: []},
               %{papers: [%{word: nil}, %{word: %{value: "foo", author: "a"}}]},
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

      {:ok, game} = Game.set_question(game, "1", "foo", "a")

      assert [
               %{papers: []},
               %{papers: [%{question: nil}, %{question: %{value: "foo", author: "a"}}]},
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

      {:ok, game} = Game.set_poem(game, "1", "foo", "a")

      assert [
               %{papers: [%{poem: %{value: "foo", author: "a"}}]},
               %{papers: [%{poem: nil}]},
               %{papers: [%{poem: nil}]}
             ] = game.seats
    end
  end

  defp demo_game() do
    with game = Game.init("game_id"),
         {:ok, game} <- Game.add_member(game, %{id: "1"}),
         {:ok, game} <- Game.add_member(game, %{id: "2"}),
         {:ok, game} <- Game.add_member(game, %{id: "3"}) do
      {:ok, game}
    end
  end
end
