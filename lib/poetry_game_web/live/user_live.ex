defmodule PoetryGame.Live.UserLive do
  use Phoenix.LiveView,
    container: {:div, class: "user-live"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint

  import PoetryGameWeb.LiveHelpers

  @max_name_length 12

  @impl true
  def render(assigns) do
    max_name_length = @max_name_length

    ~H"""
    <div class="h-full bg-black/30 absolute inset-0 place-content-center" style={"z-index: 10000; #{if @show, do: "display: flex;", else: "display: none;"}"}
      phx-capture-click="hide"
    >
      <form action="#"
        class="shadow overflow-hidden rounded-lg max-w-sm bg-white p-4 mx-auto my-auto relative min-w-max"
        phx-change="change"
        phx-debounce="200"
        phx-hook="UserForm"
        phx-key="escape"
        phx-window-keydown="hide"
        id={"user_form-#{@user.id}"}
      >
        <a href="#" class="phx-modal-close absolute top-0 right-0 p-2 z-10" phx-click={"hide"}>✖</a>

        <%= if !@user.name || !@user.color do %>
          <p class="mb-4 text-sm text-slate-500">You will need to set your name before you can join a game.</p>
        <% end %>

        <div class="mb-4">
          <label for="name" class="font-bold text-gray-700 mb-1 block">Name</label>
          <input id="name" type="text" name="user[name]" autocomplete="given-name" maxlength={max_name_length}
            class="text-xl p-2 font-semibold shadow-inner focus:ring-indigo-500 focus:border-indigo-500 block w-full rounded-md border border-stone-300"
            style={user_hsl(@user.color)}
            value={@user.name}>
        </div>

        <div class="mb-4">
          <label for="color" class="block font-bold text-gray-700 mb-1 block">Color</label>
          <input id="color" type="range" min="0" max="359" value={@user.color} name="user[color]" class="slider block w-full mb-2">
          <div class="py-2"
            style="background: linear-gradient(to right, #ff0000 0%, #ffff00 17%, #00ff00 33%, #00ffff 50%, #0000ff 67%, #ff00ff 83%, #ff0000 100%);">
          </div>
        </div>

        <div>
          <button type="submit" class="p-2 font-semibold outline-none bg-amber-100 focus:bg-amber-200 hover:bg-amber-200">
            Save
          </button>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"user" => user, "game_id" => game_id}, socket) do
    Endpoint.subscribe("user_form:#{user.id}")

    {
      :ok,
      assign(
        socket,
        user: user,
        game_id: game_id,
        show: false
      )
    }
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

  def handle_info(%{event: "user_form", payload: %{show: show}}, socket) do
    {:noreply, assign(socket, show: show)}
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
