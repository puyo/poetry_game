defmodule PoetryGame.GameServer do
  use GenServer, restart: :transient

  # ----------------------------------------------------------------------
  # client

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def state(game_id) do
    # Agent.get(via(game_id), fn state -> state end)
    GenServer.call(via(game_id), :get_state)
  end

  def join_game(game_id, user_id) do
    GenServer.call(via(game_id), {:join_game, user_id})
  end

  def leave_game(game_id, user_id) do
    GenServer.call(via(game_id), {:leave_game, user_id})
  end

  def start_game(game_id) do
    GenServer.call(via(game_id), {:set_status, :playing})
  end

  # ----------------------------------------------------------------------
  # server

  @impl true
  def init(game_id) do
    {:ok,
     %{
       game_id: game_id,
       game: %{},
       players: %{},
       non_players: %{},
       chat_messages: []
     }}
  end

  @impl true
  def handle_call(:get_state, from, state) do
    {:reply, state, state}
  end

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end
end
