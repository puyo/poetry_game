defmodule PoetryGame.Game do
  defstruct(
    id: nil,
    members: %{},
    seats: []
  )

  def init(game_id) do
    %__MODULE__{
      id: game_id,
      members: %{},
      seats: []
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
      |> Enum.map(fn {{id, _}, _i} ->
        %{member_id: id, papers: [initial_paper()]}
      end)

    {:ok, %{game | seats: seats}}
  end

  def started?(game) do
    length(game.seats) > 0
  end

  def finished?(game) do
    length(game.seats) > 0 &&
      paper_list(game)
      |> Enum.all?(&paper_finished?/1)
  end

  def paper_finished?(paper) do
    paper.word && paper.question && paper.poem
  end

  def can_start?(game) do
    !started?(game) && map_size(game.members) >= @min_players
  end

  def number_of_extra_players_needed(game) do
    max(@min_players - map_size(game.members), 0)
  end

  def paper_index_within_seat(game, paper_id) do
    seat_index = paper_seat_index(game, paper_id)
    seat = Enum.at(game.seats, seat_index)
    Enum.find_index(seat.papers, fn p -> p.id == paper_id end)
  end

  @doc "Given a paper_id, find which seat is it at"
  def paper_seat_index(game, paper_id) do
    Enum.find_index(game.seats, fn seat ->
      Enum.find(seat.papers, fn p -> p.id == paper_id end)
    end)
  end

  def add_member(game, %{id: id}) do
    if Map.has_key?(game.members, id) do
      {:ok, game}
    else
      members = Map.put(game.members, id, %{id: id})
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

  def set_word(game, user_id, word, author) do
    with {:ok, game, user_index} <- set_value(game, user_id, :word, word, author) do
      move_paper_to_next_seat(game, user_index)
    end
  end

  def set_question(game, user_id, question, author) do
    with {:ok, game, user_index} <- set_value(game, user_id, :question, question, author) do
      move_paper_to_next_seat(game, user_index)
    end
  end

  def set_poem(game, user_id, poem, author) do
    with {:ok, game, _user_index} <- set_value(game, user_id, :poem, poem, author) do
      {:ok, game}
    end
  end

  def player_list(game) do
    game.seats
    |> Enum.map(fn seat ->
      Map.get(game.members, seat && seat.member_id)
    end)
  end

  def paper_list(game) do
    game.seats
    |> Enum.flat_map(fn %{papers: papers} -> papers end)
  end

  def user_at_seat(game, seat_index) do
    seat = Enum.at(game.seats, seat_index)
    Map.get(game.members, seat && seat.member_id)
  end

  def user_seat_index(game, user_id) do
    Enum.find_index(game.seats, fn seat -> seat.member_id == user_id end)
  end

  def bootstrap(game) do
    {:ok,
     %{
       game
       | seats:
           game.seats
           |> put_in(
             [Access.all(), :papers, Access.all(), :word],
             %{
               value: "word #{Enum.random(0..10)}",
               author: "Author #{Enum.random(0..10)}"
             }
           )
           |> put_in(
             [Access.all(), :papers, Access.all(), :question],
             %{
               value: "question #{Enum.random(0..10)}",
               author: "Author #{Enum.random(0..10)}"
             }
           )
     }}
  end

  defp initial_paper() do
    %{
      id: Ecto.UUID.generate(),
      word: nil,
      question: nil,
      poem: nil
    }
  end

  defp set_value(game, user_id, key, value, author) do
    case user_seat_index(game, user_id) do
      nil ->
        {:error, :invalid}

      index ->
        seats =
          put_in(game.seats, [Access.at!(index), :papers, Access.at!(0), key], %{
            value: value,
            author: author
          })

        {:ok, %{game | seats: seats}, index}
    end
  rescue
    Enum.OutOfBoundsError -> {:error, :invalid}
  end

  defp move_paper_to_next_seat(game, user_index) do
    num_seats = length(game.seats)
    insert_index = rem(user_index + 1, num_seats)

    # remove paper from current seat paper list
    {paper, seats} = pop_in(game.seats, [Access.at!(user_index), :papers, Access.at!(0)])

    # append it to the new seat paper list
    seats =
      update_in(
        seats,
        [Access.at!(insert_index), :papers],
        fn papers -> List.insert_at(papers, -1, paper) end
      )

    {:ok, %{game | seats: seats}}
  end
end
