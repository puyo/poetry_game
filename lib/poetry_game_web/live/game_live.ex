defmodule PoetryGame.GameLive do
  use Phoenix.LiveView,
    container: {:div, class: "game-live h-full flex bg-red-800 text-white"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGame.{Game, GameServer, GameSupervisor}

  def render(assigns) do
    cx = assigns.width / 2
    cy = assigns.height / 3
    squish = 0.25
    radius = assigns.width / 3
    angle_offset = 0.5 * :math.pi()

    ~H"""
    <%= live_render(@socket, PoetryGame.PresenceLive, id: "presence-#{@id}", session: %{"topic" => @id}) %>
    <div id={"game_board_#{@id}"} class="grow" phx-hook="GameSize">
      <%= if Game.started?(@game) do %>
        <% nseats = length(@game.seats) %>
        <% user_seat_index = Game.user_seat_index(@game, @user_id) %>

        <ul class="hidden">
          <li>User ID: <%= String.slice(@user_id, 0..3) %></li>
          <li>nseats: <%= nseats %></li>
          <li>user_seat_index: <%= user_seat_index %></li>
        </ul>

        <%= for {seat, seat_i} <- Enum.with_index(@game.seats) do %>
          <% rotation_i = rem(seat_i - user_seat_index + nseats, nseats) %>
          <% seat_angle = 2.0 * :math.pi * rotation_i / nseats %>
          <% seatx = cx + radius * :math.cos(angle_offset + seat_angle) %>
          <% seaty = cy + squish * radius * :math.sin(angle_offset + seat_angle) %>

          <div class="seat" id={"seat-#{seat_i}"} style={"top: #{seaty}px; left: #{seatx}px"} data-width={"#{@width}"}>
            <ul class="xhidden">
              <li>Seat <%= seat_i %></li>
              <li>npapers <%= length(seat.papers) %></li>
            </ul>
            <% user = Game.user_at_seat(@game, seat_i) %>
            <%= if user do %>
              <span class="user-name" style={"color: hsl(#{user.color}, 50%, 50%)"}><%= user.name %></span>
            <% else %>
              <span class="user-name">(VACANT)</span>
            <% end %>
          </div>

          <% paper_angle = @rotate + 2.0 * (:math.pi) * rotation_i / nseats %>
          <% paper_angle = if paper_angle > 2.0 * :math.pi, do: paper_angle - 2.0 * :math.pi, else: paper_angle %>
          <% paperx = cx + radius * :math.cos(angle_offset + paper_angle) %>
          <% papery = cy + squish * radius * :math.sin(angle_offset + paper_angle) %>
          <% paperz = trunc(100 * (1 + :math.cos(paper_angle))) %>

          <%= for {paper, paper_i} <- Enum.with_index(seat.papers) do %>
            <% visible = paper_i == 0 && user_seat_index == seat_i %>

            <div
                class="paper"
                id={"paper-#{paper.id}"}
                style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz};"}  data-width={"#{@width}"}>

              <p class="text-slate-400 text-xs mb-4"><%= paper.id %></p>
              <%= if visible do %>
                <div id={"paper-content-#{paper.id}"}>
                  <div class="word">
                    Word: <%= paper.word %>
                  </div>
                  <div class="question">
                    Question: <%= paper.question %>
                  </div>
                  <div class="poem">
                    <%= for line <- String.split(paper.poem || "", "\n") do %>
                      <div class="line"><%= line %></div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>

      <% else %>
        NOT STARTED

      CAN START =
      <%= Game.can_start?(@game) %>
      <% end %>
    </div>
    <div class="chat w-[20em]">
      <%= live_render(@socket, PoetryGame.ChatLive, id: "chat-#{@id}", session: %{"topic" => @id}) %>
    </div>
    """
  end

  def mount(
        _params,
        %{
          "id" => game_id,
          "user_id" => user_id,
          "user_name" => user_name,
          "user_color" => user_color
        } = session,
        socket
      ) do
    user = %{id: user_id, name: user_name, color: user_color}

    with {:ok, game} <- setup_live_view_process(game_id, user) do
      broadcast_game_state_update!(game_id, game)

      IO.inspect(mount: user_id)

      {:ok,
       assign(
         socket,
         game: game,
         id: game_id,
         user_id: user_id,
         user_name: user_name,
         rotate: 0.0,
         width: 0,
         height: 0
       )}
    end
  end

  defp setup_live_view_process(game_id, user) do
    game_id
    |> ensure_game_process_exists()
    |> subscribe_to_updates()
    |> ensure_player_joins(user)
  end

  defp ensure_game_process_exists(game_id) do
    case GameSupervisor.start_child({GameServer, game_id}) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:ok, game_id}
      _ -> {:error, game_id}
    end
  end

  defp subscribe_to_updates({:ok, game_id}) do
    PoetryGame.PubSub.subscribe_to_game_updates(game_id)
    game_id
  end

  defp ensure_player_joins(game_id, user) do
    with {:ok, game} <- GameServer.add_member(game_id, user) do
      if length(game.seats) == 0 && Game.can_start?(game) do
        Game.start(game)
      else
        {:ok, game}
      end
    end
  end

  defp broadcast_game_state_update!(game_id, game) do
    PoetryGame.PubSub.broadcast_game_update!(game_id, game)
  end

  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    {:noreply, assign(socket, width: width, height: height)}
  end

  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    IO.inspect(game_state_update: socket.assigns.user_id)
    {:noreply, assign(socket, game: game)}
  end
end
