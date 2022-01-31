defmodule PoetryGame.Game do
  alias PoetryGame.Room

  @name :poetry_game

  @initial_game_state %{
    players: []
  }

  @initial_paper %{
    word: nil,
    question: nil,
    poem: nil
  }

  @min_players 3

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @name)
    state = add_initial_state(Room.initial_state())
    Agent.start_link(fn -> state end, opts)
  end

  defp add_initial_state(state) do
    %{state | game: @initial_game_state}
  end

  def start_game(pid) do
    Agent.get_and_update(pid, fn state ->
      cond do
        map_size(state.room.members) < @min_players ->
          {{:error, :too_few_players}, state}

        true ->
          new_state = new_game_state(state)
          {{:ok, new_state}, new_state}
      end
    end)
  end

  defp new_game_state(state) do
    new_players =
      state.room.members
      |> Enum.map(&player_from_member/1)

    put_in(state, [:game, :players], new_players)
  end

  # TODO: decide what to do when somebody up and leaves mid-game
  #
  # Currently, if one of the players leaves, just end the game completely and
  # potentially re-start it
  #
  def remove_player(pid, user_name) do
    Agent.get_and_update(pid, fn state ->
      if is_playing(state, user_name) do
        new_state = %{state | game: @initial_game_state}
        {{:ok, new_state}, new_state}
      else
        {{:ok, state}, state}
      end
    end)
  end

  defp is_playing(state, user_name) do
    index =
      state.game.players
      |> Enum.find_index(fn u -> user_name == u.name end)

    index != nil
  end

  def set_word(pid, user_name, word) do
    set_value(pid, user_name, :word, word, false)
  end

  def set_question(pid, user_name, question) do
    set_value(pid, user_name, :question, question, false)
  end

  def set_poem(pid, user_name, poem) do
    set_value(pid, user_name, :poem, poem, true)
  end

  defp player_from_member({name, _member}) do
    %{name: name, papers: [@initial_paper]}
  end

  defp update_paper_in_place(players, player_index, new_paper) do
    put_in(
      players,
      [Access.at(player_index), :papers, Access.at(0)],
      new_paper
    )
  end

  defp update_paper_and_move(players, player_index, new_paper) do
    {_old_paper, players} =
      pop_in(
        players,
        [Access.at(player_index), :papers, Access.at(0)]
      )

    insert_index = rem(player_index + 1, length(players))

    update_in(
      players,
      [Access.at(insert_index), :papers],
      fn papers -> List.insert_at(papers, -1, new_paper) end
    )
  end

  defp set_value(pid, user_name, key, value, is_last_key) do
    Agent.get_and_update(pid, fn state ->
      old_index =
        state.game.players
        |> Enum.find_index(fn u ->
          user_name == u.name
        end)

      old_player = state.game.players |> Enum.at(old_index)

      [old_paper | _] = old_player.papers

      new_paper = %{old_paper | key => value}

      new_players =
        if is_last_key do
          update_paper_in_place(state.game.players, old_index, new_paper)
        else
          update_paper_and_move(state.game.players, old_index, new_paper)
        end

      new_state = put_in(state, [:game, :players], new_players)
      {{:ok, new_state}, new_state}
    end)
  end
end
