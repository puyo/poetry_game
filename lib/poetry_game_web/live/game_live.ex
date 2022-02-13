defmodule PoetryGame.GameLive do
  use Phoenix.LiveView,
    container: {:div, class: "game-live h-full flex bg-red-800 text-white"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGame.{Game, GameServer, GameSupervisor, LiveMonitor, PubSub}

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

    papers = Game.paper_list(game) |> Enum.sort_by(fn p -> p.id end)
    chat_topic = "chat:#{game.id}"

    ~H"""
    <div id={"game_#{@game_id}"} class={"game grow #{@settled}"} phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"}>
      <%= if @game_started do %>
        <div class="board">
          <%= for {seat, seat_i} <- Enum.with_index(@game.seats) do %>
            <%= render_seat(seat, seat_i, assigns) %>
          <% end %>
          <%= for paper <- papers do %>
            <%= render_paper(paper, assigns) %>
          <% end %>
        </div>
      <% end %>
    </div>
    <div class="chat w-[20em]" style="z-index: 1000;">
      <%= live_render(@socket, PoetryGame.ChatLive, id: "chat-#{@game_id}", session: %{"topic" => chat_topic}) %>
    </div>
    """
  end

  def render(%{game: game, width: width, height: height} = assigns) do
    ~H"""
    <div id={"game_#{@game_id}"} class="grow" phx-hook="GameSize" data-width={"#{@width}"} data-height={"#{@height}"} />
    """
  end

  def render(assigns), do: ~H""

  defp render_seat(seat, seat_i, assigns) do
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
    poetry_time = own_paper && paper.word && paper.question && !paper.poem

    paperx =
      if poetry_time do
        cx
      else
        cx + radius * :math.cos(angle_offset + paper_angle) + offset
      end

    papery =
      if poetry_time do
        cy
      else
        cy + squish * radius * :math.sin(angle_offset + paper_angle) -
          offset
      end

    paperz = trunc(100 * (1 + :math.cos(paper_angle))) - offset
    visible = game_finished || own_paper

    max_width = width
    max_height = height - papery / 2

    ~H"""
    <div
      class="paper"
      id={"paper-#{paper.id}"}
      style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz}; max-width: #{max_width}px; max-height: #{max_height}px;"}
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
  def handle_event(
        "submit_value",
        %{"word" => value},
        %{assigns: %{game_id: game_id, user_id: user_id}} = socket
      ) do
    GameServer.set_word(game_id, user_id, value)
    {:noreply, socket}
  end

  def handle_event(
        "submit_value",
        %{"question" => value},
        %{assigns: %{game_id: game_id, user_id: user_id}} = socket
      ) do
    GameServer.set_question(game_id, user_id, value)
    {:noreply, socket}
  end

  def handle_event(
        "submit_value",
        %{"poem" => value},
        %{assigns: %{game_id: game_id, user_id: user_id}} = socket
      ) do
    GameServer.set_poem(game_id, user_id, value)
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

  @impl true
  # GameServer pubsub events (broadcast_game_update!)
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(:settle, socket) do
    {:noreply, assign(socket, settled: "settled")}
  end
end
