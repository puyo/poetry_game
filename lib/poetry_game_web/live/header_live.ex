defmodule PoetryGame.Live.HeaderLive do
  use Phoenix.LiveView,
    container: {:div, class: "shrink"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint
  alias PoetryGameWeb.Router.Helpers, as: Routes

  import PoetryGameWeb.LiveHelpers

  def render(assigns) do
    ~H"""
    <header class="shrink" style="z-index: 1000;">
      <div class="bg-white border-b-4 border-black border-solid">
        <div class="container mx-auto">
          <div class="flex justify-between items-center">
            <a href="/" class="logo justify-start px-1 py-2">
              <img src={Routes.static_path(@socket, "/images/poetry-game.svg")} alt="Poetry Game"/>
            </a>
            <a href="#" class="user justify-end p-2 text-xl hover:bg-amber-300 rounded-md" phx-click="show-form">
              <% color = @user.color %>
              <% name = @user.name %>
              <span class="font-semibold text-black text-xl"
                style={"color: hsl(#{color}, 70%, 45%)"}><%= name %></span>
              <img style="vertical-align: baseline; height: 1em"
                src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename" class="inline"/>
            </a>
          </div>
        </div>
      </div>
    </header>
    <%= if @show_form do %>
      <%= live_render(@socket, PoetryGame.Live.UserLive, id: "user-#{@user.id}", session: %{"user" => @user}) %>
    <% end %>
    """
  end

  defp user_hsl(color), do: "hsl(#{color}, 70%, 45%)"

  def mount(_params, %{"game_id" => game_id, "user" => user} = session, socket) do
    {:ok,
     assign(
       socket,
       user: user,
       game_id: game_id,
       show_form: false
     )}
  end

  @impl true
  def handle_event("change", %{"user" => %{"color" => color, "name" => name}}, socket) do
    new_user =
      Map.merge(
        socket.assigns.user,
        %{name: name, color: String.to_integer(color)}
      )

    {:noreply, assign(socket, user: new_user)}
  end

  def handle_event("update-user", %{"user" => %{"color" => color, "name" => name}}, socket) do
    new_user =
      Map.merge(
        socket.assigns.user,
        %{name: name, color: String.to_integer(color)}
      )

    Endpoint.local_broadcast("user:#{socket.assigns.user.id}", "update-user", new_user)

    {:noreply, assign(socket, user: new_user, show_form: false)}
  end

  def handle_event("show-form", _, socket) do
    {:noreply, assign(socket, show_form: true)}
  end
end
