defmodule PoetryGame.GameServerTest do
  use ExUnit.Case, async: true

  @id "test-id"

  alias PoetryGame.GameServer

  setup do
    {:ok, _pid} = GameServer.start_link(@id)
    :ok
  end

  test "sets up initial state" do
    state = GameServer.state(@id)
    assert state.game_id == @id
  end

  # test "add a member" do
  #   {:ok, state} = GameServer.add_room_member(@id, "Greg")

  #   assert state.room.members == %{
  #            "Greg" => %{name: "Greg"}
  #          }
  # end

  # test "name too short" do
  #   {status, reason} = GameServer.add_room_member(@id, "")
  #   assert status == :error
  #   assert reason == :name_too_short
  # end

  # test "name taken" do
  #   assert {:ok, _} = GameServer.add_room_member(@id, "Greg")
  #   assert {:error, :name_taken} = GameServer.add_room_member(@id, "Greg")
  # end

  # test "remove a member" do
  #   assert {:ok, _} = GameServer.add_room_member(@id, "Greg")
  #   assert {:ok, state} = GameServer.remove_room_member(@id, "Greg")
  #   assert state.room.members == %{}
  # end
end
