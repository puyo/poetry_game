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

  describe "started?/1" do
    test "false until game starts, then true even if game finishes" do
      {:ok, game} = demo_game()
      assert Game.started?(game) == false
      {:ok, game} = Game.start(game)
      assert Game.started?(game) == true
      {:ok, game} = finish_demo_game(game)
      assert Game.started?(game) == true
    end
  end

  describe "finished?/1" do
    test "false until the game is finished" do
      {:ok, game} = demo_game()
      assert Game.finished?(game) == false
      {:ok, game} = Game.start(game)
      assert Game.finished?(game) == false
      {:ok, game} = finish_demo_game(game)
      assert Game.finished?(game) == true
    end
  end

  describe "number_of_extra_players_needed/1" do
    test "starts at 3, goes to 0 when players are joined, does not go below 0" do
      game = Game.init("game_id")
      assert Game.number_of_extra_players_needed(game) == 3
      {:ok, game} = demo_game()
      assert Game.number_of_extra_players_needed(game) == 0
      {:ok, game} = Game.add_member(game, %{id: "4"})
      assert Game.number_of_extra_players_needed(game) == 0
    end
  end

  describe "paper_index_within_seat/2" do
    test "" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      paper1_id = get_in(game.seats, [Access.at(0), :papers, Access.at(0), :id])
      {:ok, game} = Game.set_word(game, "1", "w1", "user1")
      assert Game.paper_index_within_seat(game, paper1_id) == 1
    end
  end

  describe "bootstrap/1" do
    test "sets words and questions in a started game" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      {:ok, game} = Game.bootstrap(game)
      paper_word = get_in(game.seats, [Access.at(0), :papers, Access.at(0), :word, :value])
      assert not is_nil(paper_word)
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

    test "failure, no such user" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      assert {:error, :invalid} = Game.set_word(game, "non-existant", "foo", "a")
    end

    test "failure, user has no paper" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      {:ok, game} = Game.set_word(game, "1", "foo", "a")
      assert {:error, :invalid} = Game.set_word(game, "1", "foo", "a")
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

  describe "set_player_ready/3" do
    test "success" do
      {:ok, game} = demo_game()
      {:ok, game} = Game.start(game)
      {:ok, game} = finish_demo_game(game)
      {:ok, game} = Game.set_player_ready(game, "1", true)
      {:ok, game} = Game.set_player_ready(game, "2", true)
      {:ok, game} = Game.set_player_ready(game, "3", true)

      assert [
               %{papers: [%{poem: nil}]},
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

  defp finish_demo_game(game) do
    with {:ok, game} <- Game.set_word(game, "1", "w1", "user1"),
         {:ok, game} <- Game.set_word(game, "2", "w2", "user2"),
         {:ok, game} <- Game.set_word(game, "3", "w3", "user3"),
         {:ok, game} <- Game.set_question(game, "1", "q1", "user1"),
         {:ok, game} <- Game.set_question(game, "2", "q2", "user2"),
         {:ok, game} <- Game.set_question(game, "3", "q3", "user3"),
         {:ok, game} <- Game.set_poem(game, "1", "p1", "user1"),
         {:ok, game} <- Game.set_poem(game, "2", "p2", "user2"),
         {:ok, game} <- Game.set_poem(game, "3", "p3", "user3") do
      {:ok, game}
    end
  end
end
