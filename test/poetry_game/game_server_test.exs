defmodule PoetryGame.GameServerTest do
  use ExUnit.Case, async: true

  @id "test-game-id"

  alias PoetryGame.GameServer

  setup do
    {:ok, _pid} = GameServer.start_link(@id)
    :ok
  end

  describe "start_link/1" do
    test "sets up initial state" do
      assert %PoetryGame.Game{} = GameServer.game(@id)
    end
  end

  describe "start_game/1" do
    test "successfully" do
      start_demo_game()
      {:ok, player_list} = GameServer.player_list(@id)
      {:ok, paper_list} = GameServer.paper_list(@id)
      assert length(player_list) == 3
      assert length(paper_list) == 3
    end

    test "too few players" do
      assert {:error, :too_few_players} = GameServer.start_game(@id)
    end
  end

  describe "add_member/2" do
    test "already added" do
      {:ok, _} = GameServer.add_member(@id, %{id: "1", name: "A", color: 1})
      assert {:ok, _} = GameServer.add_member(@id, %{id: "1", name: "A", color: 1})
    end
  end

  describe "remove_member/2" do
    test "not found" do
      assert {:error, :not_found} = GameServer.remove_member(@id, "1")
    end

    test "success" do
      {:ok, _} = GameServer.add_member(@id, %{id: "1", name: "A", color: 1})
      assert {:ok, _} = GameServer.remove_member(@id, "1")
    end
  end

  describe "set_word/3" do
    test "success" do
      start_demo_game()
      assert {:ok, _state} = GameServer.set_word(@id, "1", "foo", "author")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_word(@id, "1", "", "author")
    end
  end

  describe "set_question/3" do
    test "success" do
      start_demo_game()
      assert {:ok, _state} = GameServer.set_question(@id, "1", "foo", "author")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_question(@id, "1", "", "author")
    end
  end

  describe "set_poem/3" do
    test "success" do
      start_demo_game()
      assert {:ok, _state} = GameServer.set_poem(@id, "1", "foo", "author")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_poem(@id, "1", "", "author")
    end
  end

  describe "bootstrap/1" do
    test "success" do
      start_demo_game()
      assert {:ok, game} = GameServer.bootstrap(@id)
      paper_word = get_in(game.seats, [Access.at(0), :papers, Access.at(0), :word, :value])
      assert not is_nil(paper_word)
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_poem(@id, "1", "", "author")
    end
  end

  describe "terminate/1" do
    test "does not terminate the game if there are still members" do
      game_id = "not_terminated_because_not_empty"
      {:ok, _pid} = GameServer.start_link(game_id)
      {:ok, _} = GameServer.add_member(game_id, %{id: "1", name: "A", color: 1})
      :ok = GameServer.terminate(game_id)
      refute GameServer.game(game_id) == nil
    end

    test "terminates the game if there are no members" do
      game_id = "terminated_because_empty"
      assert {:noproc, _} = game_server_get_state(game_id)
      PoetryGame.GameSupervisor.start_child({GameServer, game_id})
      :ok = GameServer.terminate(game_id)
      assert {:shutdown, _} = game_server_get_state(game_id)
    end
  end

  defp game_server_get_state(game_id) do
    try do
      {:ok, game} = GameServer.game(game_id)
      game
    catch
      :exit, value ->
        value
    end
  end

  defp start_demo_game() do
    {:ok, _} = GameServer.add_member(@id, %{id: "1", name: "A", color: 1})
    {:ok, _} = GameServer.add_member(@id, %{id: "2", name: "B", color: 2})
    {:ok, _} = GameServer.add_member(@id, %{id: "3", name: "C", color: 3})
    {:ok, state} = GameServer.start_game(@id)
    state
  end
end
