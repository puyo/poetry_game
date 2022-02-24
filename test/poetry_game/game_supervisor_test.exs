defmodule PoetryGame.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias PoetryGame.GameSupervisor

  describe "start_child/1" do
    test "success" do
      assert {:ok, _pid} = GameSupervisor.start_child({PoetryGame.GameServer, "supervised"})
    end
  end

  describe "terminate_child/1" do
    test "success, terminated" do
      game_id = "supervised_and_terminated"
      {:ok, _pid} = GameSupervisor.start_child({PoetryGame.GameServer, game_id})
      assert :ok = GameSupervisor.terminate_child(game_id)
    end

    test "failure" do
      game_id = "does_not_exist"
      assert {:error, :not_found, ^game_id} = GameSupervisor.terminate_child(game_id)
    end
  end
end
