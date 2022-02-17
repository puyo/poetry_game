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
    <div class="container">
      <div class="flex justify-between items-center">
        <div class="justify-start">
          <img class="logo" src={Routes.static_path(@socket, "/images/poetry-game.svg")} alt="Poetry Game"/>
        </div>
        <%= if @user do %>
          <div class="justify-end">
            <button class="btn-show-user-form" phx-click="show_form">
              <% color = @user.color %>
              <% name = @user.name %>
              <span class="user-name" style={user_hsl(color)}><%= name %></span>
              <img class="icon edit-icon" src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename"/>
            </button>
          </div>
        <% end %>
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
