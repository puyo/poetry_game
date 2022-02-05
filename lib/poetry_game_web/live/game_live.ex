defmodule PoetryGame.GameLive do
  use PoetryGameWeb, :live_view
  alias PoetryGame.Room

  def render(assigns) do
    ~H"""
    <div class="game">
      <div class="origin" style={"position: absolute; top: #{@cy}px; left: #{@cx}px; width: 10px; height: 10px; background-color: blue; z-index: 1000; transform: translate(-50%, -50%)"}></div>
      <% nplayers = length(@players) %>
      <% angle_offset = 0.5 * :math.pi %>
      <%= for {player, i} <- Enum.with_index(@players) do %>
        <% player_angle = 2.0 * :math.pi * i / nplayers %>
        <% playerx = @cx + @radius * :math.cos(angle_offset + player_angle) %>
        <% playery = @cy + @squish * @radius * :math.sin(angle_offset + player_angle) %>
        <% playerz = trunc(100 * (1 + :math.cos(player_angle))) %>

        <div class="player" id={"player-#{player.name}"} style={"top: #{playery}px; left: #{playerx}px"}>
          <span class="name"><%= player.name %></span>
        </div>

        <% paper_angle = @rotate + 2.0 * (:math.pi) * i / nplayers %>
        <% paper_angle = if paper_angle > 2.0 * :math.pi, do: paper_angle - 2.0 * :math.pi, else: paper_angle %>
        <% paperx = @cx + @radius * :math.cos(angle_offset + paper_angle) %>
        <% papery = @cy + @squish * @radius * :math.sin(angle_offset + paper_angle) %>
        <% paperz = trunc(100 * (1 + :math.cos(paper_angle))) %>

        <% flipped = paper_angle > 0.1 && paper_angle < (2.0 * :math.pi - 0.1) %>

        <% paperscalemin = -1.0 %>
        <% paperscalemax = 1.0 %>
        <% paperscale = paperscalemin + (paperscalemax - paperscalemin) * (paperz / 200.0) %>

        <%= for paper <- player.papers do %>
          <div class="paper" style={"top: #{papery}px; left: #{paperx}px; z-index: #{paperz}; transform: translate(-50%, 0) scale(#{if flipped, do: 1.0, else: 1.0}, 1.0);"}>
            <!-- a = <%= Float.round(paper_angle, 2) %>, flipped = <%= flipped %> -->
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
      <% end %>
    </div>
    """
  end

  @initial_paper %{
    word: "A word",
    question: "A question?",
    poem:
      "There once was a man from kentucket\nwho had a very big bucket\nhe ate lots of fish\nand stole a big dish\nand everybody shrugged and said oh well"
  }

  def mount(_params, _session, socket) do
    state =
      socket
      |> assign(:rotate, 0.0)
      |> assign(:cx, 400)
      |> assign(:cy, 200)
      |> assign(:squish, 0.25)
      |> assign(:radius, 300)
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
      |> assign(:timer, Process.send_after(self(), :tick, 1_000))

    {:ok, state}
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
