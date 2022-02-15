defmodule PoetryGame.Live.HeaderLive do
  use Phoenix.LiveView,
    container: {:div, class: "shrink"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint
  alias PoetryGameWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <header class="shrink" style="z-index: 1000;">
      <div class="bg-white border-b-4 border-black border-solid">
        <div class="container mx-auto">
          <div class="flex justify-between items-center">
            <a href="/" class="logo justify-start px-1 py-2">
              <img src={Routes.static_path(@socket, "/images/poetry-game.svg")} alt="Poetry Game"/>
            </a>
            <a href="#" class="user justify-end p-2 text-xl hover:bg-amber-300 rounded-md" phx-click="show_form">
              <% color = @user.color %>
              <% name = @user.name %>
              <span class="font-semibold text-black text-xl"
                style={"color: #{user_hsl(color)}"}><%= name %></span>
              <img style="vertical-align: baseline; height: 1em"
                src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename" class="inline"/>
            </a>
          </div>
        </div>
      </div>
    </header>
    <%= if @show_form do %>
      <%= live_render(@socket, PoetryGame.Live.UserLive, id: "user-#{@user.id}", session: %{"user" => @user, "game_id" => @game_id}) %>
    <% end %>
    """
  end

  defp user_hsl(color), do: "hsl(#{color}, 70%, 45%)"

  @impl true
  def mount(_params, %{"game_id" => game_id, "user" => user}, socket) do
    # updates
    Endpoint.subscribe("users")
    # show/hide form
    Endpoint.subscribe("user:#{user.id}")

    {:ok,
     assign(
       socket,
       user: user,
       game_id: game_id,
       show_form: false
     )}
  end

  @impl true
  def handle_event("show_form", _, socket) do
    Endpoint.local_broadcast("user:#{socket.assigns.user.id}", "user_form", %{show: true})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "user_form", payload: %{show: show_form}}, socket) do
    {:noreply, assign(socket, show_form: show_form)}
  end

  def handle_info(%{event: "update_user", payload: user}, socket) do
    socket =
      if user.id == socket.assigns.user.id do
        assign(socket, user: user)
      else
        socket
      end

    {:noreply, socket}
  end
end
