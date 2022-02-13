defmodule PoetryGame.GameLive do
  use Phoenix.LiveView,
    container: {:div, class: "game-live h-full flex bg-red-800 text-white"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGame.{Game, GameServer, GameSupervisor, LiveMonitor, PubSub}
  alias PoetryGameWeb.Presence

  @impl true
  def render(%{width: width, height: height, game: game, user_id: user_id} = assigns)
      when width > 0 and height > 0 do
    cx = width / 2
    cy = height / 3
    squish = 0.25
    radius = width / 3
    angle_offset = 0.5 * :math.pi()
    game_started = Game.started?(game)
    game_finished = Game.finished?(game)

    user_seat_index = Game.user_seat_index(game, user_id) || 0
    nseats = length(assigns.game.seats)

    settled = assigns.settled

    ~H"""
    <%= live_render(@socket, PoetryGame.PresenceLive, id: "presence-#{@game_id}", session: %{"topic" => @game_id}) %>
    <div id={"game_#{@game_id}"} class={"game grow #{settled}"} phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"}>
      <%= if game_started do %>

        <ul class="hidden">
          <li>User ID: <%= String.slice(@user_id, 0..3) %></li>
          <li>nseats: <%= nseats %></li>
          <li>user_seat_index: <%= user_seat_index %></li>
        </ul>

        <%= for {seat, seat_i} <- Enum.with_index(@game.seats) do %>
          <% seat_rotation_i = rem(seat_i - user_seat_index + nseats, nseats) %>
          <% seat_angle = 2.0 * :math.pi * seat_rotation_i / nseats %>
          <% seatx = cx + radius * :math.cos(angle_offset + seat_angle) %>
          <% seaty = cy + squish * radius * :math.sin(angle_offset + seat_angle) %>

          <div class="seat" id={"seat-#{seat_i}"} style={"top: #{seaty}px; left: #{seatx}px"} data-width={"#{@width}"} data-height={"#{@height}"}>
            <ul class="hidden">
              <li>Seat <%= seat_i %></li>
              <li>npapers <%= length(seat.papers) %></li>
            </ul>
            <% user = Game.user_at_seat(@game, seat_i) %>
            <%= if user do %>
              <span class="user-name" style={"color: hsl(#{user.color}, 50%, 50%)"}><%= user.name %></span>
            <% else %>
              <span class="user-name text-black">(VACANT)</span>
            <% end %>
          </div>
        <% end %>

        <%= for paper <- Game.paper_list(@game) |> Enum.sort_by(fn p -> p.id end) do %>
          <% paper_i = Game.paper_index_within_seat(@game, paper.id) %>
          <% seat_i = Game.paper_seat_index(@game, paper.id) %>
          <% seat_rotation_i = rem(seat_i - user_seat_index + nseats, nseats) %>
          <% paper_angle = @rotate + 2.0 * (:math.pi) * seat_rotation_i / nseats %>
          <% paper_angle = if paper_angle > 2.0 * :math.pi, do: paper_angle - 2.0 * :math.pi, else: paper_angle %>
          <% paperx = cx + radius * :math.cos(angle_offset + paper_angle) %>
          <% papery = cy + squish * radius * :math.sin(angle_offset + paper_angle) %>
          <% paperz = trunc(100 * (1 + :math.cos(paper_angle))) %>
          <% offset = paper_i * 10 %>
          <% visible = game_finished || paper_i == 0 && user_seat_index == seat_i %>

          <div
            class="paper"
            id={"paper-#{paper.id}"}
            style={"top: #{papery - offset}px; left: #{paperx + offset}px; z-index: #{paperz - offset};"}
            data-width={"#{@width}"}
            data-height={"#{@height}"}>

            <p class="hidden text-slate-400 text-xs mb-4"><%= String.slice(paper.id, 0..5) %> P(<%= paper_i %>) S(<%= seat_i %>)</p>
            <%= if visible do %>
              <%= render_paper(paper, assigns, game_finished) %>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    <div class="chat w-[20em]" style="z-index: 1000;">
      <%= live_render(@socket, PoetryGame.ChatLive, id: "chat-#{@game_id}", session: %{"topic" => @game_id}) %>
    </div>
    """
  end

  def render(%{width: width, height: height} = assigns) do
    ~H"""
    <div class="grow" phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"} />
    """
  end

  def render(assigns) do
    ~H"""
    """
  end

  defp render_paper(paper, assigns, game_finished) do
    ~H"""
    <div id={"paper-content-#{paper.id}"}>
      <form action="#" phx-submit="submit_value">
        <%= if paper.word do %>
          <div class="word">
            Word: <%= paper.word %>
          </div>
        <% else %>
          <div class="word">
            <input type="text" name="word" placeholder="Enter a word"
              class="focus:border-none outline-none border-none" />
          </div>
        <% end %>

        <%= if paper.question do %>
          <div class="question">
            Question: <%= paper.question %>
          </div>
        <% else %>
          <%= if paper.word do %>
            <div class="question">
              <input type="text" name="question" placeholder="Enter a question"
                class="focus:border-none outline-none border-none" />
            </div>
          <% end %>
        <% end %>

        <%= if paper.poem do %>
          <div class="poem">
            <%= for line <- String.split(paper.poem || "", "\n") do %>
              <div class="line"><%= line %></div>
            <% end %>
          </div>
          <%= if !game_finished do %>
            <p class="mt-4 text-slate-500">Waiting on other players...</p>
          <% end %>
        <% else %>
          <%= if paper.word && paper.question do %>
            <div class="poem">
              <textarea name="poem" rows="5" placeholder="Write a poem using the word and question above"
                class="focus:border-none outline-none border-none"
              />
              <button type="submit"
                  class="p-2 font-semibold outline-none bg-amber-100 focus:bg-amber-200 hover:bg-amber-200">
                Save
              </button>
            </div>
          <% end %>
        <% end %>
      </form>
    </div>
    """
  end

  @impl true
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

    with true <- connected?(socket),
         {:ok, pid} <- ensure_game_process_exists(game_id),
         :ok <- subscribe_to_updates(game_id, user),
         {:ok, game} <- ensure_player_joins(game_id, user),
         :ok <- monitor_live_view_process(game_id, user) do
      # Allow width/height to trigger, allow layout to settle, then apply card
      # transition css
      Process.send_after(self(), :tick, 100)

      {
        :ok,
        assign(
          socket,
          game: game,
          game_id: game_id,
          user_id: user_id,
          user_name: user_name,
          rotate: 0.0,
          width: 0,
          height: 0,
          settled: ""
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

  defp subscribe_to_updates(game_id, user) do
    Presence.track(self(), game_id, user.id, user)
    PubSub.subscribe_to_game_updates(game_id)
    :ok
  end

  defp ensure_player_joins(game_id, user) do
    with {:ok, game} <- GameServer.add_member(game_id, user) do
      if length(game.seats) == 0 && Game.can_start?(game) do
        GameServer.start_game(game_id)
      else
        {:ok, game}
      end
    end
  end

  @impl true
  def handle_event("submit_value", %{"word" => value}, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id
    GameServer.set_word(game_id, user_id, value)
    {:noreply, socket}
  end

  def handle_event("submit_value", %{"question" => value}, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id
    GameServer.set_question(game_id, user_id, value)
    {:noreply, socket}
  end

  def handle_event("submit_value", %{"poem" => value}, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id
    GameServer.set_poem(game_id, user_id, value)
    {:noreply, socket}
  end

  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    {:noreply, assign(socket, width: width, height: height)}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    IO.inspect(game_live: self(), event: "game_state_update")
    {:noreply, assign(socket, game: game)}
  end

  # Presence.track callback
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    IO.inspect(game_live: self(), joins: map_size(joins), leaves: map_size(leaves))

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, settled: "settled")}
  end
end
