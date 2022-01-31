defmodule PoetryGame.RoomTest do
  use ExUnit.Case, async: true

  @name __MODULE__

  alias PoetryGame.Room

  setup do
    Agent.start_link(fn -> Room.initial_state() end, name: @name)
    :ok
  end

  test "initial value" do
    state = Room.state(@name)
    assert state == %{room: %{members: %{}, messages: []}, game: %{}}
  end

  test "add a member" do
    {:ok, state} = Room.add_room_member(@name, "Greg")

    assert state.room.members == %{
             "Greg" => %{name: "Greg"}
           }
  end

  test "name too short" do
    {status, reason} = Room.add_room_member(@name, "")
    assert status == :error
    assert reason == :name_too_short
  end

  test "name taken" do
    assert {:ok, _} = Room.add_room_member(@name, "Greg")
    assert {:error, :name_taken} = Room.add_room_member(@name, "Greg")
  end

  test "remove a member" do
    assert {:ok, _} = Room.add_room_member(@name, "Greg")
    assert {:ok, state} = Room.remove_room_member(@name, "Greg")
    assert state.room.members == %{}
  end
end
