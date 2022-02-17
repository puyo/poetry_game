defmodule PoetryGame.Live.HeaderLive do
  use Phoenix.LiveView,
    container: {:div, class: "shrink"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint
  alias PoetryGameWeb.Router.Helpers, as: Routes

  import PoetryGameWeb.LiveHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white border-b-4 border-black border-solid">
      <div class="container mx-auto">
        <div class="flex justify-between items-center">
          <a href="/" class="logo justify-start px-1 py-2">
            <img src={Routes.static_path(@socket, "/images/poetry-game.svg")} alt="Poetry Game"/>
          </a>
          <%= if @user do %>
            <a href="#" class="user justify-end p-2 text-xl hover:bg-amber-300 rounded-md" phx-click="show_form">
              <% color = @user.color %>
              <% name = @user.name %>
              <span class="font-semibold text-xl" style={user_hsl(color)}><%= name %></span>
              <img style="vertical-align: baseline; height: 1em"
                src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename" class="inline"/>
            </a>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"user" => user}, socket) do
    # show/hide form, update user
    Endpoint.subscribe("user:#{user.id}")
    {:ok, assign(socket, user: user)}
  end

  def mount(_params, _, socket) do
    {:ok, assign(socket, user: nil)}
  end

  @impl true
  def handle_event("show_form", _, socket) do
    Endpoint.local_broadcast("user_form:#{socket.assigns.user.id}", "user_form", %{show: true})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "update_user", payload: user}, socket) do
    {:noreply, assign(socket, user: user)}
  end
end
