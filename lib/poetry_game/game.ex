defmodule PoetryGame.Game do
  defstruct(
    id: nil,
    members: %{},
    seats: [],
    chat_messages: []
  )

  def init(game_id) do
    %__MODULE__{
      id: game_id,
      members: %{},
      seats: [],
      chat_messages: []
    }
  end

  @min_players 3

  def start(game) do
    players =
      game.members
      |> Enum.with_index()
      |> Enum.sort_by(fn {_, index} -> index end)

    seats =
      players
      |> Enum.map(fn _ ->
        %{papers: [initial_paper()]}
      end)

    members =
      players
      |> Enum.map(fn {{user_id, member}, index} ->
        {user_id, Map.put(member, :seat_index, index)}
      end)
      |> Enum.into(%{})

    {:ok, %{game | seats: seats, members: members}}
  end

  def started?(game) do
    length(game.seats) > 0
  end

  def finished?(game) do
    paper_list(game)
    |> Enum.all?(&paper_finished?/1)
  end

  def paper_finished?(paper) do
    paper.word && paper.question && paper.poem
  end

  def can_start?(game) do
    map_size(game.members) >= @min_players
  end

  def add_member(game, %{id: id, name: name, color: color}) do
    if Map.has_key?(game.members, id) do
      {:ok, game}
    else
      members = Map.put(game.members, id, %{id: id, name: name, color: color})
      {:ok, %{game | members: members}}
    end
  end

  def remove_member(game, user_id) do
    if Map.has_key?(game.members, user_id) do
      members = Map.delete(game.members, user_id)
      {:ok, %{game | members: members}}
    else
      {:error, :not_found}
    end
  end

  def set_word(game, user_id, word) do
    with {:ok, game} <- set_value(game, user_id, :word, word) do
      move_paper_to_next_seat(game, user_id)
    end
  end

  def set_question(game, user_id, question) do
    with {:ok, game} <- set_value(game, user_id, :question, question) do
      move_paper_to_next_seat(game, user_id)
    end
  end

  def set_poem(game, user_id, poem) do
    set_value(game, user_id, :poem, poem)
  end

  def player_list(%{members: members}) do
    members
    |> Map.values()
    |> Enum.filter(fn m -> Map.has_key?(m, :seat_index) end)
  end

  def paper_list(game) do
    game.seats
    |> Enum.flat_map(fn %{papers: papers} -> papers end)
  end

  def user_at_seat(game, seat_index) do
    game.members
    |> Map.values()
    |> Enum.find(fn m -> m.seat_index == seat_index end)
  end

  def user_seat_index(game, user_id) do
    get_in(game.members, [user_id, :seat_index])
  end

  defp initial_paper() do
    %{
      id: Ecto.UUID.generate(),
      word: nil,
      question: nil,
      poem: nil
    }
  end

  defp set_value(game, user_id, key, value) do
    index = user_seat_index(game, user_id)
    seats = put_in(game.seats, [Access.at!(index), :papers, Access.at!(0), key], value)
    {:ok, %{game | seats: seats}}
  rescue
    KeyError -> {:error, :invalid}
  end

  defp move_paper_to_next_seat(game, user_id) do
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

    {:ok, %{game | seats: seats}}
  rescue
    KeyError -> {:error, :invalid}
  end
end
