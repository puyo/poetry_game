defmodule PoetryGame.Room do
  @initial_state %{
    game: %{},
    room: %{
      members: %{},
      messages: []
    }
  }

  def initial_state do
    @initial_state
  end

  def state(pid) do
    Agent.get(pid, fn state -> state end)
  end

  def add_room_member(pid, user_name)
  def add_room_member(_, ""), do: {:error, :name_too_short}

  def add_room_member(pid, user_name) do
    Agent.get_and_update(pid, fn state ->
      if state.room.members |> Map.has_key?(user_name) do
        {{:error, :name_taken}, state}
      else
        new_member = %{name: user_name}

        new_state =
          state
          |> put_in([:room, :members, user_name], new_member)

        {{:ok, new_state}, new_state}
      end
    end)
  end

  def remove_room_member(pid, user_name) do
    Agent.get_and_update(pid, fn state ->
      {_member, new_state} =
        state
        |> pop_in([:room, :members, Access.key!(user_name)])

      {{:ok, new_state}, new_state}
    end)
  end
end
