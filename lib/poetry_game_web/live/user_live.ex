defmodule PoetryGame.Live.UserLive do
  use Phoenix.LiveView,
    container: {:div, class: "user-live"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint
  alias PoetryGameWeb.Router.Helpers, as: Routes

  import PoetryGameWeb.LiveHelpers

  @max_name_length 12

  @impl true
  def render(assigns) do
    max_name_length = @max_name_length

    ~H"""
    <button class="btn btn-transparent" phx-click="show">
      <% color = @user.color %>
      <% name = @user.name %>
      <span class="user-name" style={user_hsl(color)}><%= name %></span>
      <img class="icon edit-icon" src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename"/>
    </button>
    <%= if @show do %>
      <div class="user-form modal-bg" style={if @show, do: "display: flex;", else: "display: none;"} phx-capture-click="hide">
        <form action="#"
          class="modal"
          phx-change="change"
          phx-debounce="200"
          phx-hook="UserForm"
          phx-key="escape"
          phx-window-keydown="hide"
          id={"user_form-#{@user.id}"}
        >
          <a href="#" class="modal-close btn btn-transparent" phx-click={"hide"}>✖</a>

          <div class="field">
            <label for="name" class="block-label">Name</label>
            <input id="name" type="text" name="user[name]" autocomplete="given-name" maxlength={max_name_length}
              class="user-name"
              style={user_hsl(@user.color)}
              value={@user.name}>
          </div>

          <div class="field">
            <label for="color" class="block-label">Color</label>
            <input id="color" type="range" min="0" max="359" value={@user.color} name="user[color]">
            <div class="rainbow-bg">
              &nbsp;
            </div>
          </div>

          <div class="buttons">
            <button type="submit" class="btn btn-secondary">Save</button>
          </div>
        </form>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"user" => user}, socket) do
    Endpoint.subscribe("user:#{user.id}")

    {:ok, assign(socket, user: user, show: false)}
  end

  @impl true
  def handle_event("change", input, socket) do
    new_user = Map.merge(socket.assigns.user, sanitize_input(input))
    {:noreply, assign(socket, user: new_user)}
  end

  def handle_event("submit", input, socket) do
    new_user = Map.merge(socket.assigns.user, sanitize_input(input))
    Endpoint.local_broadcast("user:all", "update_user", new_user)
    Endpoint.local_broadcast("user:#{new_user.id}", "update_user", new_user)
    {:noreply, assign(socket, user: new_user, show: false)}
  end

  def handle_event("hide", _, socket) do
    {:noreply, assign(socket, show: false)}
  end

  def handle_event("show", _, socket) do
    {:noreply, assign(socket, show: true)}
  end

  @impl true
  def handle_info(%{event: "update_user", payload: user}, socket) do
    socket =
      if user.id == socket.assigns.user.id do
        assign(socket, user: user)
      else
        socket
      end

    {:noreply, socket}
  end

  defp sanitize_input(%{"user" => %{"name" => name, "color" => color}}) do
    %{name: sanitize_name(name), color: sanitize_color(color)}
  end

  defp sanitize_name(name) do
    name
    |> String.trim()
    |> String.slice(0..@max_name_length)
  end

  defp sanitize_color(color) do
    color
    |> String.to_integer()
    |> rem(360)
  end
end
