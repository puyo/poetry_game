defmodule PoetryGame.GameTest do
  use ExUnit.Case, async: true

  @name __MODULE__

  alias PoetryGame.{Game, Room}

  setup do
    Game.start_link(name: @name)
    :ok
  end

  test "start game" do
    {:error, :too_few_players} = Game.start_game(@name)
    {:ok, _} = Room.add_room_member(@name, "A")
    {:ok, _} = Room.add_room_member(@name, "B")
    {:ok, _} = Room.add_room_member(@name, "C")
    {:ok, state} = Game.start_game(@name)
    first_player = state.game.players |> Enum.at(0)
    assert first_player.papers |> length == 1
  end

  test "remove player" do
    {:ok, _} = Room.add_room_member(@name, "A")
    {:ok, _} = Room.add_room_member(@name, "B")
    {:ok, _} = Room.add_room_member(@name, "C")
    {:ok, _} = Game.start_game(@name)
    {:ok, state} = Game.remove_player(@name, "B")
    # reset to initial
    assert state.game.players == []
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

  test "set word, question, poem" do
    {:ok, _} = Room.add_room_member(@name, "A")
    {:ok, _} = Room.add_room_member(@name, "B")
    {:ok, _} = Room.add_room_member(@name, "C")
    {:ok, _} = Game.start_game(@name)
    {:ok, state} = Game.set_word(@name, "A", "WA")

    assert state.game.players == [
             %{name: "A", papers: []},
             %{
               name: "B",
               papers: [
                 %{poem: nil, question: nil, word: nil},
                 %{poem: nil, question: nil, word: "WA"}
               ]
             },
             %{
               name: "C",
               papers: [
                 %{poem: nil, question: nil, word: nil}
               ]
             }
           ]

    {:ok, _} = Game.set_word(@name, "B", "WB")
    {:ok, state} = Game.set_question(@name, "B", "QB")

    assert state.game.players == [
             %{name: "A", papers: []},
             %{name: "B", papers: []},
             %{
               name: "C",
               papers: [
                 %{poem: nil, question: nil, word: nil},
                 %{poem: nil, question: nil, word: "WB"},
                 %{poem: nil, question: "QB", word: "WA"}
               ]
             }
           ]

    {:ok, _} = Game.set_word(@name, "C", "C")
    {:ok, _} = Game.set_question(@name, "C", "QC")
    {:ok, state} = Game.set_poem(@name, "C", "PC")

    assert state.game.players == [
             %{
               name: "A",
               papers: [
                 %{poem: nil, question: nil, word: "C"},
                 %{poem: nil, question: "QC", word: "WB"}
               ]
             },
             %{name: "B", papers: []},
             %{
               name: "C",
               papers: [
                 %{poem: "PC", question: "QB", word: "WA"}
               ]
             }
           ]
  end
end
