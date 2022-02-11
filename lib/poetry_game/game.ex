defmodule PoetryGame.Game do
  defstruct(
    members: %{},
    seats: [],
    chat_messages: []
  )

  def init() do
    %__MODULE__{
      members: %{},
      seats: [],
      chat_messages: []
    }
  end

  def start(game) do
    players =
      game.members
      |> Enum.with_index()
      |> Enum.sort_by(fn {_, index} -> index end)

    seats =
      players
      |> Enum.map(fn {{user_id, _member}, _index} ->
        %{papers: [initial_paper()]}
      end)

    members =
      players
      |> Enum.map(fn {{user_id, member}, index} ->
        {user_id, Map.put(member, :seat_index, index)}
      end)
      |> Enum.into(%{})

    %{game | seats: seats, members: members}
  end

  def add_member(game, %{id: id, name: name, color: color}) do
    if Map.has_key?(game.members, id) do
      {:error, :already_added}
    else
      members = Map.put(game.members, id, %{id: id, name: name, color: color})
      %{game | members: members}
    end
  end

  def remove_member(game, user_id) do
    if Map.has_key?(game.members, user_id) do
      members = Map.delete(game.members, user_id)
      %{game | members: members}
    else
      {:error, :not_found}
    end
  end

  def set_word(game, user_id, word) do
    game
    |> set_value(user_id, :word, word)
    |> move_paper_to_next_seat(user_id)
  end

  def set_value(game, user_id, key, value) do
    index = user_seat_index(game, user_id)
    seats = put_in(game.seats, [Access.at!(index), :papers, Access.at!(0), key], value)
    %{game | seats: seats}
  end

  def user_seat_index(game, user_id) do
    get_in(game.members, [user_id, :seat_index])
  end

  def move_paper_to_next_seat(game, user_id) do
    old_index = user_seat_index(game, user_id)
    num_seats = length(game.seats)
    insert_index = rem(old_index + 1, num_seats)

    # remove paper from current seat paper list
    {paper, seats} = pop_in(game.seats, [Access.at!(old_index), :papers, Access.at!(0)])

    # append it to the new seat paper list
    seats =
      update_in(
        seats,
        [Access.at!(insert_index), :papers],
        fn papers -> List.insert_at(papers, -1, paper) end
      )

    %{game | seats: seats}
  end

  def player_list(game) do
    game.seats
    |> Enum.filter(fn %{user_id: user_id} -> Map.has_key?(game.members, user_id) end)
    |> Enum.map(fn %{user_id: user_id} -> Map.get(game.members, user_id) end)
  end

  def paper_list(game) do
    game.seats
    |> Enum.flat_map(fn %{papers: papers} -> papers end)
  end

  defp initial_paper() do
    %{
      id: Ecto.UUID.generate(),
      word: nil,
      question: nil,
      poem: nil
    }
  end

  # defp set_value(pid, user_name, key, value, is_last_key) do
  #   Agent.get_and_update(pid, fn state ->
  #     old_index =
  #       state.game.players
  #       |> Enum.find_index(fn u ->
  #         user_name == u.name
  #       end)

  #     old_player = state.game.players |> Enum.at(old_index)

  #     [old_paper | _] = old_player.papers

  #     new_paper = %{old_paper | key => value}

  #     new_players =
  #       if is_last_key do
  #         update_paper_in_place(state.game.players, old_index, new_paper)
  #       else
  #         update_paper_and_move(state.game.players, old_index, new_paper)
  #       end

  #     new_state = put_in(state, [:game, :players], new_players)
  #     {{:ok, new_state}, new_state}
  #   end)
  # end
end
