defmodule PoetryGame.GameSupervisor do
  @moduledoc """
  Start and stop games on the fly at runtime.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child) do
    DynamicSupervisor.start_child(__MODULE__, child)
  end

  @spec terminate_child(String.t()) :: :ok | {:error, :not_found}
  def terminate_child(game_id) do
    with [{child_pid, _}] <- Registry.lookup(:game_registry, game_id) do
      DynamicSupervisor.terminate_child(__MODULE__, child_pid)
    else
      [] -> {:error, :not_found, game_id}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
