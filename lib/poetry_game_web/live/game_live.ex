defmodule PoetryGame.Live.GameLive do
  use Phoenix.LiveView,
    container: {:div, class: "game-live h-full"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.{Endpoint, Presence}
  alias PoetryGame.{Game, GameServer, GameSupervisor, LiveMonitor, PubSub}
  alias PoetryGameWeb.Router.Helpers, as: Routes

  import PoetryGameWeb.LiveHelpers

  @impl true
  def render(%{width: width, height: height, game: game, user: user} = assigns)
      when width > 0 and height > 0 do
    assigns =
      Map.merge(
        assigns,
        %{
          game_finished: Game.finished?(game),
          user_seat_index: Game.user_seat_index(game, user.id) || 0,
          nseats: length(game.seats)
        }
      )

    ~H"""
    <% finished_class = if Game.finished?(@game), do: "finished", else: "" %>
    <div class={"game h-full #{@settled} #{finished_class}"}
        id={"game-hook-#{@game_id}"}
        phx-hook="GameSize"
        data-width={@width}
        data-height={@height}>
      <%= if Game.started?(@game) do %>
        <div class="game-board">
          <%= for {_seat, seat_i} <- Enum.with_index(@game.seats) do %>
            <%= render_seat(seat_i, assigns) %>
          <% end %>
          <% papers = Game.paper_list(game) |> Enum.sort_by(fn p -> p.id end) %>
          <%= for paper <- papers do %>
            <%= render_paper(paper, assigns) %>
          <% end %>
        </div>
      <% else %>
        <div class="modal-bg modal-bg-local">
          <div class="modal pre-game-info">
            <p>
              <%= if Game.can_start?(@game) do %>
                <button class="btn btn-primary btn-lg" phx-click="start">Start Game</button>
              <% else %>
                <button class="btn btn-primary btn-lg" disabled>Start Game</button>
              <% end %>
            </p>
            <p>
              <% players_needed = max(0, 3 - map_size(@users)) %>
              Waiting for <%= players_needed %> more
              <%= if players_needed == 1, do: "player", else: "players" %>
            </p>
            <p>
              To get more players, copy the link below and send it to your friends
            </p>
            <p>
              <input class="game-url" type="text" value={Routes.game_url(@socket, :show, @game_id)} />
            </p>
            <div class="buttons">
              <button class="btn btn-secondary"
                id={"copy-to-clipboard-#{@game_id}"}
                phx-hook="CopyToClipboard"
                data-copy=".game-url">Copy Link</button>
            </div>
          </div>
        </div>
      <% end %>
      <input class="game-url hidden" type="text" value={Routes.game_url(@socket, :show, @game_id)} />
    </div>
    """
  end

  def render(%{game_id: game_id, width: width, height: height} = assigns) do
    ~H"""
    <div id={"game_#{game_id}"} class="grow" phx-hook="GameSize" data-width={width} data-height={height}>
      &nbsp;
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp render_seat(seat_i, assigns) do
    %{
      cx: cx,
      cy: cy,
      nseats: nseats,
      squish: squish,
      user_seat_index: user_seat_index,
      radius: radius,
      angle_offset: angle_offset
    } = assigns

    seat_rotation_i = rem(seat_i - user_seat_index + nseats, nseats)
    seat_angle = 2.0 * :math.pi() * seat_rotation_i / nseats
    seatx = cx + radius * :math.cos(angle_offset + seat_angle)
    seaty = cy + squish * radius * :math.sin(angle_offset + seat_angle)

    ~H"""
    <div class="seat" id={"seat-#{seat_i}"} style={"top: #{seaty}px; left: #{seatx}px"} data-width={@width} data-height={@height}>
      <% user = Game.user_at_seat(@game, seat_i) %>
      <%= if user do %>
        <span class="user-name" style={user_hsl(user_color(assigns, user.id))}><%= user_name(assigns, user.id) %></span>
      <% else %>
        <span class="user-name">(VACANT)</span>
      <% end %>
    </div>
    """
  end

  defp user_name(assigns, user_id) do
    case Map.get(assigns.users, user_id) do
      nil -> ""
      user -> user.name
    end
  end

  defp user_color(assigns, user_id) do
    case Map.get(assigns.users, user_id) do
      nil -> 0
      user -> user.color
    end
  end

  defp render_paper(paper, assigns) do
    %{
      cx: cx,
      cy: cy,
      nseats: nseats,
      squish: squish,
      user_seat_index: user_seat_index,
      radius: radius,
      angle_offset: angle_offset,
      game: game,
      rotate: rotate,
      game_finished: game_finished,
      width: width,
      height: height
    } = assigns

    paper_i = Game.paper_index_within_seat(game, paper.id)
    seat_i = Game.paper_seat_index(game, paper.id)
    seat_rotation_i = rem(seat_i - user_seat_index + nseats, nseats)
    paper_angle = rotate + 2.0 * :math.pi() * seat_rotation_i / nseats
    offset = paper_i * 10

    own_paper = paper_i == 0 && user_seat_index == seat_i
    composing = own_paper && paper.word && paper.question && !paper.poem
    visible = game_finished || own_paper

    c =
      cond do
        composing ->
          %{
            x: "#{cx}px",
            y: "#{cy}px",
            z: "#{trunc(100 * (1 + :math.cos(paper_angle))) - offset}",
            position: "absolute",
            max_width: "#{width}px",
            max_height: "#{height - cy / 2}px",
            transform: "",
            class: "composing"
          }

        game_finished ->
          %{
            x: "0",
            y: "0",
            z: "0",
            position: "initial",
            max_width: "#{width}px",
            max_height: "#{height}px",
            class: "finished"
          }

        true ->
          x = cx + radius * :math.cos(angle_offset + paper_angle) + offset
          y = cy + squish * radius * :math.sin(angle_offset + paper_angle) - offset

          %{
            x: "#{x}px",
            y: "#{y}px",
            z: "#{trunc(100 * (1 + :math.cos(paper_angle))) - offset}",
            position: "absolute",
            max_width: "#{width}px",
            max_height: "#{height - y / 2}px",
            class: "playing"
          }
      end

    ~H"""
    <div
      class={"paper #{c.class}"}
      id={"paper-#{paper.id}"}
      style={"top: #{c.y}; left: #{c.x}; z-index: #{c.z}; max-width: #{c.max_width}; max-height: #{c.max_height};"}
      data-width={@width}
      data-height={@height}>

      <%= if visible do %>

        <form action="#" phx-submit="submit_value" autocomplete="off">
          <%= if paper.word do %>
            <div class="paper-section word">
              <%= if paper.question do %>
                <span class="label">Word: </span><span class="value"><%= paper.word.value %></span>
                <div class="attribution">
                  &ndash;&nbsp;<%= paper.word.author %>
                </div>
              <% else %>
                (folded over)
              <% end %>
            </div>
          <% else %>
            <div class="paper-section word">
              <input class="word-input" type="text" name="word" placeholder="Enter a word" />
            </div>
          <% end %>

          <%= if paper.question do %>
            <div class="paper-section question">
              <span class="label">Question: </span><span class="value"><%= paper.question.value %></span>
              <div class="attribution">
                &ndash;&nbsp;<%= paper.question.author %>
              </div>
            </div>
          <% else %>
            <%= if paper.word do %>
              <div class="paper-section question">
                <input class="question-input" type="text" name="question" placeholder="Enter a question" />
              </div>
            <% end %>
          <% end %>

          <%= if paper.poem do %>
            <div class="paper-section poem">
              <div class="poem">
                <%= for line <- String.split(paper.poem.value || "", "\n") do %>
                  <div class="line"><%= line %></div>
                <% end %>
                <div class="attribution">
                  &ndash;&nbsp;<%= paper.poem.author %>
                </div>
              </div>
            </div>
            <%= if not @game_finished do %>
              <div class="paper-section hint">
                <p>Waiting on other players...</p>
              </div>
            <% end %>
          <% else %>
            <%= if paper.word && paper.question do %>
              <div class="paper-section poem">
                <div class="poem-input-wrapper">
                  <textarea class="poem-input" name="poem" onInput="this.parentNode.dataset.value = this.value" rows="2" placeholder="Write a poem using the word and question above"></textarea>
                </div>
                <div class="buttons">
                  <button class="btn btn-secondary" type="submit">Save</button>
                </div>
              </div>
            <% end %>
          <% end %>
        </form>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"id" => game_id, "user" => user}, socket) do
    topic = "game:#{game_id}"

    # all user updates like name/color changes
    Endpoint.subscribe("user:all")

    # user joins/leaves
    Presence.track(self(), topic, user.id, user)

    with true <- connected?(socket),
         {:ok, _pid} <- ensure_game_process_exists(game_id),
         :ok <- subscribe_to_updates(game_id),
         {:ok, game} <- ensure_player_joins(game_id, user),
         :ok <- monitor_live_view_process(game_id, user) do
      {
        :ok,
        assign(
          socket,
          game: game,
          game_id: game_id,
          topic: topic,
          user: user,
          rotate: 0.0,
          width: 0,
          height: 0,
          settled: "",
          paper_height: 400,
          squish: 0.25,
          angle_offset: 0.5 * :math.pi(),
          cx: 0,
          cy: 0,
          radius: 0,
          users: users(topic)
        )
      }
    else
      _ -> {:ok, socket}
    end
  end

  def unmount(_reason, %{user: user, game_id: game_id}) do
    GameServer.remove_member(game_id, user.id)
  end

  defp ensure_game_process_exists(game_id) do
    case GameSupervisor.start_child({GameServer, game_id}) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:ok, game_id}
      _ -> {:error, game_id}
    end
  end

  defp monitor_live_view_process(game_id, user) do
    LiveMonitor.monitor(self(), __MODULE__, %{game_id: game_id, user: user})
  end

  defp subscribe_to_updates(game_id) do
    PubSub.subscribe_to_game_updates(game_id)
    :ok
  end

  defp ensure_player_joins(game_id, user) do
    GameServer.add_member(game_id, user)
  end

  @impl true
  def handle_event(
        "submit_value",
        %{"word" => value},
        %{assigns: %{game_id: game_id, user: user}} = socket
      ) do
    GameServer.set_word(game_id, user.id, String.trim(value), user.name)
    {:noreply, socket}
  end

  def handle_event(
        "submit_value",
        %{"question" => value},
        %{assigns: %{game_id: game_id, user: user}} = socket
      ) do
    GameServer.set_question(game_id, user.id, String.trim(value), user.name)
    {:noreply, socket}
  end

  def handle_event(
        "submit_value",
        %{"poem" => value},
        %{assigns: %{game_id: game_id, user: user}} = socket
      ) do
    GameServer.set_poem(game_id, user.id, String.trim(value), user.name)
    {:noreply, socket}
  end

  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    # Allow width/height to trigger, allow layout to settle, then apply card
    # transition css
    Process.send_after(self(), :settle, 1_000)
    radius = width / 3
    cx = width / 2
    cy = height / 2

    {
      :noreply,
      assign(
        socket,
        width: width,
        height: height,
        cx: cx,
        cy: cy,
        radius: radius,
        settled: ""
      )
    }
  end

  def handle_event("start", _, %{assigns: %{game_id: game_id}} = socket) do
    with {:ok, game} <- GameServer.start_game(game_id) do
      {:noreply, assign(socket, game: game)}
    else
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(:settle, socket) do
    {:noreply, assign(socket, settled: "settled")}
  end

  def handle_info(%{event: "update_user", payload: user}, socket) do
    Presence.update(self(), socket.assigns.topic, user.id, user)

    new_user =
      if user.id == socket.assigns.user.id do
        user
      else
        socket.assigns.user
      end

    {:noreply, assign(socket, user: new_user)}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    users = users(socket.assigns.topic)
    {:noreply, assign(socket, users: users)}
  end

  defp users(topic) do
    Presence.list(topic)
    |> Enum.map(fn {id, %{metas: [%{name: name, color: color} | _others]}} ->
      {id, %{name: name, color: color}}
    end)
    |> Enum.into(%{})
  end
end
