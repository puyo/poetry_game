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
      {:ok, list} = GameServer.player_list(@id)
      assert length(list) == 3
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
      assert {:ok, _state} = GameServer.set_word(@id, "1", "foo")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_word(@id, "1", "")
    end
  end

  describe "set_question/3" do
    test "success" do
      start_demo_game()
      assert {:ok, _state} = GameServer.set_question(@id, "1", "foo")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_question(@id, "1", "")
    end
  end

  describe "set_poem/3" do
    test "success" do
      start_demo_game()
      assert {:ok, _state} = GameServer.set_poem(@id, "1", "foo")
    end

    test "invalid" do
      start_demo_game()
      assert {:error, :invalid} = GameServer.set_poem(@id, "1", "")
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
