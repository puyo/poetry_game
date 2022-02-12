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
        STARTED
      <% nseats = length(@game.seats) %>

      <%= for {seat, i} <- Enum.with_index(@game.seats) do %>
        <% seat_angle = 2.0 * :math.pi * i / nseats %>
        <% seatx = cx + radius * :math.cos(angle_offset + seat_angle) %>
        <% seaty = cy + squish * radius * :math.sin(angle_offset + seat_angle) %>
        <%# seatz = trunc(100 * (1 + :math.cos(seat_angle))) %>

        <div class="seat" id={"seat-#{i}"} style={"top: #{seaty}px; left: #{seatx}px"}>
          <span class="name">Player TODO</span>
        </div>

        <% paper_angle = @rotate + 2.0 * (:math.pi) * i / nseats %>
        <% paper_angle = if paper_angle > 2.0 * :math.pi, do: paper_angle - 2.0 * :math.pi, else: paper_angle %>
        <% paperx = cx + radius * :math.cos(angle_offset + paper_angle) %>
        <% papery = cy + squish * radius * :math.sin(angle_offset + paper_angle) %>
        <% paperz = trunc(100 * (1 + :math.cos(paper_angle))) %>

        <% visible = not (paper_angle > 0.1 && paper_angle < (2.0 * :math.pi - 0.1)) %>

        <%# paperscalemin = -1.0 %>
        <%# paperscalemax = 1.0 %>
        <%# paperscale = paperscalemin + (paperscalemax - paperscalemin) * (paperz / 200.0) %>

        <%= for {paper, paper_i} <- Enum.with_index(seat.papers) do %>
          <div
            class="paper"
            id={"paper-#{i}-#{paper_i}"}
            style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz};"}>
          <%= paper.id %>
            <%= if visible do %>
              <div id={"paper-content-#{i}-#{paper_i}"}>
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
            <% else %>
              FLIPPED
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

    message =
      if connected?(socket) do
        with {:ok, game} <- setup_live_view_process(game_id, user) do
          broadcast_game_state_update!(game_id, game)
          "OK"
        else
          {:error, code} ->
            "ERROR: #{code}" |> IO.inspect()
        end
      end

    {:ok,
     assign(
       socket,
       game: Game.init(),
       id: game_id,
       user_id: user_id,
       user_name: user_name,
       rotate: 0.0,
       width: 0,
       height: 0
     )}
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
      if Game.can_start?(game) do
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
    {:noreply,
     assign(socket,
       game: game
     )}
  end
end
