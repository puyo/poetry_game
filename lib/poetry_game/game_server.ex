defmodule PoetryGame.GameServer do
  use GenServer, restart: :transient

  alias PoetryGame.{Game, GameSupervisor}

  @terminate_timeout_ms 60_000

  # ----------------------------------------------------------------------
  # client

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def game(game_id) do
    GenServer.call(via(game_id), :get_game)
  end

  def player_list(game_id) do
    GenServer.call(via(game_id), :player_list)
  end

  def paper_list(game_id) do
    GenServer.call(via(game_id), :paper_list)
  end

  def add_member(game_id, %{id: _id, name: _name, color: _color} = user) do
    GenServer.call(via(game_id), {:add_member, user})
  end

  def remove_member(game_id, user_id) do
    GenServer.call(via(game_id), {:remove_member, user_id})
  end

  def start_game(game_id) do
    GenServer.call(via(game_id), :start_game)
  end

  def set_word(game_id, user_id, word, author) do
    GenServer.call(via(game_id), {:set_word, user_id, word, author})
  end

  def set_question(game_id, user_id, question, author) do
    GenServer.call(via(game_id), {:set_question, user_id, question, author})
  end

  def set_poem(game_id, user_id, poem, author) do
    GenServer.call(via(game_id), {:set_poem, user_id, poem, author})
  end

  def bootstrap(game_id) do
    GenServer.call(via(game_id), :bootstrap)
  end

  def terminate(game_id) do
    [{pid, _} | _] = Registry.lookup(:game_registry, game_id)
    send(pid, :terminate)
    :ok
  end

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end

  # ----------------------------------------------------------------------
  # server

  @min_players 3

  defmacrop handle_game_change(game, do: expression) do
    quote do
      with {:ok, new_game} <- unquote(expression) do
        PoetryGame.PubSub.broadcast_game_update!(new_game.id, new_game)
        {:reply, {:ok, new_game}, new_game}
      else
        error -> {:reply, error, unquote(game)}
      end
    end
  end

  def init(game_id) do
    {:ok, Game.init(game_id)}
  end

  def handle_call(:get_game, _from, game), do: {:reply, game, game}

  def handle_call({:add_member, %{id: id, name: name, color: color}}, _from, game) do
    handle_game_change(game, do: Game.add_member(game, %{id: id, name: name, color: color}))
  end

  def handle_call({:remove_member, user_id}, _from, game) do
    handle_game_change(game) do
      case Game.remove_member(game, user_id) do
        {:ok, new_game} ->
          if map_size(new_game.members) > 0 do
            {:ok, new_game}
          else
            Process.send_after(self(), :terminate, @terminate_timeout_ms)
            {:ok, new_game}
          end

        err ->
          err
      end
    end
  end

  def handle_call(:start_game, _from, %{members: members} = game)
      when map_size(members) < @min_players do
    {:reply, {:error, :too_few_players}, game}
  end

  def handle_call(:start_game, _from, game) do
    handle_game_change(game, do: Game.start(game))
  end

  def handle_call({:set_word, _, "", _}, _from, game), do: {:reply, {:error, :invalid}, game}

  def handle_call({:set_word, user_id, word, author}, _from, game) do
    handle_game_change(game, do: Game.set_word(game, user_id, word, author))
  end

  def handle_call({:set_question, _, "", _}, _from, game), do: {:reply, {:error, :invalid}, game}

  def handle_call({:set_question, user_id, question, author}, _from, game) do
    handle_game_change(game, do: Game.set_question(game, user_id, question, author))
  end

  def handle_call({:set_poem, _, "", _}, _from, game), do: {:reply, {:error, :invalid}, game}

  def handle_call({:set_poem, user_id, poem, author}, _from, game) do
    handle_game_change(game, do: Game.set_poem(game, user_id, poem, author))
  end

  def handle_call(:bootstrap, _from, game) do
    handle_game_change(game, do: Game.bootstrap(game))
  end

  def handle_call(:player_list, _from, game) do
    {:reply, {:ok, Game.player_list(game)}, game}
  end

  def handle_call(:paper_list, _from, game) do
    {:reply, {:ok, Game.paper_list(game)}, game}
  end

  def handle_info(:terminate, game) do
    if map_size(game.members) == 0 do
      IO.puts("Game timed out, terminating: #{game.id}")
      GameSupervisor.terminate_child(game.id)
    end

    {:noreply, game}
  end
end
