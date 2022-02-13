defmodule PoetryGame.GameLive do
  use Phoenix.LiveView,
    container: {:div, class: "game-live h-full flex bg-red-800 text-white"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGame.{Game, GameServer, GameSupervisor, LiveMonitor, PubSub}
  alias PoetryGameWeb.Presence

  @impl true
  def render(%{width: width, height: height, game: game, user_id: user_id} = assigns)
      when width > 0 and height > 0 do
    assigns =
      Map.merge(
        assigns,
        %{
          game_started: Game.started?(game),
          game_finished: Game.finished?(game),
          user_seat_index: Game.user_seat_index(game, user_id) || 0,
          nseats: length(game.seats)
        }
      )

    ~H"""
    <div id={"game_#{@game_id}"} class={"game grow #{@settled}"} phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"}>
      <%= if @game_started do %>

        <div class="board">

          <%= for {seat, seat_i} <- Enum.with_index(@game.seats) do %>
            <%= render_seat(seat, seat_i, assigns) %>
          <% end %>

          <%= for paper <- Game.paper_list(@game) |> Enum.sort_by(fn p -> p.id end) do %>
            <%= render_paper(paper, assigns) %>
          <% end %>

        </div>

      <% end %>
    </div>
    <div class="chat w-[20em]" style="z-index: 1000;">
      <%= live_render(@socket, PoetryGame.ChatLive, id: "chat-#{@game_id}", session: %{"topic" => @game_id}) %>
    </div>
    """
  end

  def render(%{game: game, width: width, height: height} = assigns) do
    ~H"""
    <div id={"game_#{@game_id}"} class="grow" phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"} />
    """
  end

  def render(assigns) do
    ~H"""
    """
  end

  defp render_seat(seat, seat_i, assigns) do
    seat_rotation_i = rem(seat_i - assigns.user_seat_index + assigns.nseats, assigns.nseats)
    seat_angle = 2.0 * :math.pi() * seat_rotation_i / assigns.nseats
    seatx = assigns.cx + assigns.radius * :math.cos(assigns.angle_offset + seat_angle)

    seaty =
      assigns.cy + assigns.squish * assigns.radius * :math.sin(assigns.angle_offset + seat_angle)

    ~H"""
    <div class="seat" id={"seat-#{seat_i}"} style={"top: #{seaty}px; left: #{seatx}px"} data-width={"#{@width}"} data-height={"#{@height}"}>
      <% user = Game.user_at_seat(@game, seat_i) %>
      <%= if user do %>
        <span class="user-name" style={"color: hsl(#{user.color}, 50%, 50%)"}><%= user.name %></span>
      <% else %>
        <span class="user-name text-black">(VACANT)</span>
      <% end %>
    </div>
    """
  end

  defp render_paper(paper, assigns) do
    paper_i = Game.paper_index_within_seat(assigns.game, paper.id)
    seat_i = Game.paper_seat_index(assigns.game, paper.id)
    seat_rotation_i = rem(seat_i - assigns.user_seat_index + assigns.nseats, assigns.nseats)
    paper_angle = assigns.rotate + 2.0 * :math.pi() * seat_rotation_i / assigns.nseats
    offset = paper_i * 10
    paperx = assigns.cx + assigns.radius * :math.cos(assigns.angle_offset + paper_angle) + offset

    papery =
      assigns.cy + assigns.squish * assigns.radius * :math.sin(assigns.angle_offset + paper_angle) -
        offset

    paperz = trunc(100 * (1 + :math.cos(paper_angle))) - offset
    visible = assigns.game_finished || (paper_i == 0 && assigns.user_seat_index == seat_i)

    ~H"""
    <div
      class="paper"
      id={"paper-#{paper.id}"}
      style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz}; max-width: #{0.8 * @width}px; max-height: #{0.8 * @height}px;"}
      data-width={"#{@width}"}
      data-height={"#{@height}"}>

      <%= if visible do %>

        <form action="#" phx-submit="submit_value">
          <%= if paper.word do %>
            <section class="word">
              <span class="label">Word: </span><span class="value"><%= paper.word %></span>
            </section>
          <% else %>
            <section class="word">
              <input type="text" name="word" placeholder="Enter a word" class="outline-none" />
            </section>
          <% end %>

          <%= if paper.question do %>
            <section class="question">
              <span class="label">Question: </span><span class="value"><%= paper.question %></span>
            </section>
          <% else %>
            <%= if paper.word do %>
              <section class="question">
                <input type="text" name="question" placeholder="Enter a question" class="outline-none" />
              </section>
            <% end %>
          <% end %>

          <%= if paper.poem do %>
            <section class="poem">
              <div class="poem">
                <%= for line <- String.split(paper.poem || "", "\n") do %>
                  <div class="line"><%= line %></div>
                <% end %>
              </div>
            </section>
            <%= if not @game_finished do %>
              <section class="hint text-slate-500 text-sm">
                <p>Waiting on other players...</p>
              </section>
            <% end %>
          <% else %>
            <%= if paper.word && paper.question do %>
              <section class="poem">
                <div
                  id={"poem_input-#{@game_id}"}
                  class="input outline-none"
                  contenteditable
                  data-placeholder="Write a poem using the word and question above"
                  phx-hook="TextAreaSave"
                  data-textarea-id={"poem_text_area-#{@game_id}"}
                  phx-update="ignore"
                ></div>
                <textarea name="poem" style="display: none" id={"poem_text_area-#{@game_id}"}></textarea>
                <button
                  class="p-2 font-semibold outline-none bg-amber-100 focus:bg-amber-200 hover:bg-amber-200"
                  >
                  Save
                </button>
              </section>
            <% end %>
          <% end %>
        </form>
      <% end %>
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
          settled: "",
          paper_height: 400,
          squish: 0.25,
          angle_offset: 0.5 * :math.pi(),
          cx: 0,
          cy: 0,
          radius: 0
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
    # Allow width/height to trigger, allow layout to settle, then apply card
    # transition css
    Process.send_after(self(), :tick, 100)
    radius = width / 3
    cx = width / 2

    cy =
      (height - socket.assigns.paper_height + socket.assigns.squish * socket.assigns.radius) / 2

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

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, settled: "settled")}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
