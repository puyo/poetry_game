defmodule PoetryGame.GameLive do
  use PoetryGameWeb, :live_view

  def render(assigns) do
    cx = assigns.width / 2
    cy = assigns.height / 3
    radius = assigns.width / 3
    nplayers = length(assigns.players)
    angle_offset = 0.5 * :math.pi()

    ~H"""
    <div id={"game_#{@id}"} class="game" phx-hook="GameSize">
      Game ID: <%= @id %>
      User ID: <%= @user_id %>
      User Name: <%= @user_name %>
      <div class="origin"
        style={"position: absolute; top: #{cy}px; left: #{cx}px; width: 10px; height: 10px; background-color: blue; z-index: 1000; transform: translate(-50%, -50%)"}>
      </div>

      <div class="chat">
        <%= for message <- @chat do %>
          <p><%= Map.get(message, "content") %></p>
        <% end %>
        <div class="form-group">
          <form action="#" phx-submit="message">
            <%= text_input :message, :content, placeholder: "write your message here..." %>
            <%= hidden_input :message, :user_id, value: @user_id  %>
            <%= hidden_input :message, :game_id, value: @id %>
            <%= submit "submit" %>
          </form>
        </div>
      </div>

      <%= for {player, i} <- Enum.with_index(@players) do %>
        <% player_angle = 2.0 * :math.pi * i / nplayers %>
        <% playerx = cx + radius * :math.cos(angle_offset + player_angle) %>
        <% playery = cy + @squish * radius * :math.sin(angle_offset + player_angle) %>
        <%# playerz = trunc(100 * (1 + :math.cos(player_angle))) %>

        <div class="player" id={"player-#{player.name}"} style={"top: #{playery}px; left: #{playerx}px"}>
          <span class="name">Player <%= player.name %></span>
        </div>

        <% paper_angle = @rotate + 2.0 * (:math.pi) * i / nplayers %>
        <% paper_angle = if paper_angle > 2.0 * :math.pi, do: paper_angle - 2.0 * :math.pi, else: paper_angle %>
        <% paperx = cx + radius * :math.cos(angle_offset + paper_angle) %>
        <% papery = cy + @squish * radius * :math.sin(angle_offset + paper_angle) %>
        <% paperz = trunc(100 * (1 + :math.cos(paper_angle))) %>

        <% visible = not (paper_angle > 0.1 && paper_angle < (2.0 * :math.pi - 0.1)) %>

        <%# paperscalemin = -1.0 %>
        <%# paperscalemax = 1.0 %>
        <%# paperscale = paperscalemin + (paperscalemax - paperscalemin) * (paperz / 200.0) %>

        <%= for {paper, paper_i} <- Enum.with_index(player.papers) do %>
          <div
            class="paper"
            id={"paper-#{i}-#{paper_i}"}
            style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz};"}>
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
    </div>
    """
  end

  def mount(_params, %{"id" => id} = session, socket) do
    state =
      socket
      |> assign(:id, Map.get(session, "id"))
      |> assign(:user_id, Map.get(session, "user_id"))
      |> assign(:user_name, Map.get(session, "user_name"))
      |> assign(:rotate, 0.0)
      |> assign(:squish, 0.25)
      |> assign(:chat, [])
      |> assign(:message, "")
      |> assign(:width, 0)
      |> assign(:height, 0)
      |> assign(:players, [
        %{
          name: "A",
          papers: [
            %{
              word: "kentucket",
              question: "what would you do if I stole your dish?",
              poem:
                "There once was a man from kentucket\nwho had a very big bucket\nhe ate lots of fish\nand stole a big dish\nand everybody shrugged and said oh well"
            }
          ]
        },
        %{
          name: "B",
          papers: [
            %{
              word: "jobkeeper but for bees",
              question: "Don't you even dare and no this is not a question",
              poem: nil
            }
          ]
        },
        %{
          name: "C",
          papers: [
            %{
              word: "pen",
              question:
                "How long can a question even be? Like, is it OK to write a short novel in here?",
              poem: nil
            }
          ]
        }
      ])
      |> assign(:timer, Process.send_after(self(), :tick, 0))

    {:ok, state}
  end

  def handle_event("message", %{"message" => message_params}, socket) do
    {:noreply, assign(socket, chat: [message_params | socket.assigns.chat], message: "")}
  end

  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    socket =
      socket
      |> assign(:width, width)
      |> assign(:height, height)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    pi2 = 2.0 * :math.pi()
    rotate = socket.assigns.rotate + 0.05

    rotate =
      if rotate >= pi2 do
        rotate - pi2
      else
        rotate
      end

    socket =
      socket
      |> assign(:rotate, rotate)
      |> assign(:timer, Process.send_after(self(), :tick, 100))

    {:noreply, socket}
  end
end
