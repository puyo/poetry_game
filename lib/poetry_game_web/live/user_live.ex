defmodule PoetryGame.UserLive do
  use Phoenix.LiveView,
    container: {:div, class: "user-live h-full"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.{Endpoint, Presence}

  def render(assigns) do
    ~H"""
    <div class="h-full bg-stone-300 py-20">
    <form action="#"
      class="shadow overflow-hidden rounded-lg max-w-sm bg-white p-4 mx-auto"
      phx-change="change"
      phx-debounce="200"
      phx-submit="submit"
    >
        <p class="mb-4 text-sm text-slate-500">You will need to set your name before you can join a game.</p>

        <div class="mb-4 flex-inline">
          <label for="user[name]" class="shrink font-bold text-gray-700">Name:&nbsp;</label>
          <input type="text" name="user[name]" id="first-name" autocomplete="given-name"
            class="text-xl py-2 font-semibold focus:ring-indigo-500 focus:border-indigo-500 w-full grow"
            style={"color: #{user_hsl(@user.color)}"}
            value={@user.name}
          >
        </div>

        <div class="mb-4"
          >
          <label for="user[color]" class="block font-bold text-gray-700">Color</label>
          <input type="range" min="0" max="359" value={@user.color} name="user[color]"
            class="slider block w-full mb-2"
          >
          <div
          class="py-2"
          style="background: linear-gradient(to right, #ff0000 0%, #ffff00 17%, #00ff00 33%, #00ffff 50%, #0000ff 67%, #ff00ff 83%, #ff0000 100%);"
              >
              </div>
        </div>

        <div>
          <button type="submit"
            class="p-2 font-semibold outline-none bg-amber-100 focus:bg-amber-200 hover:bg-amber-200"
          >
            Save
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp user_hsl(color), do: "hsl(#{color}, 70%, 45%)"

  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    user_name = Map.get(session, "user_name")
    user_color = Map.get(session, "user_color")

    user = %{
      id: user_id,
      name: user_name,
      color: user_color
    }

    {:ok, assign(socket, user: user)}
  end

  def handle_event("change", %{"user" => %{"color" => color, "name" => name}}, socket) do
    user = socket.assigns.user

    new_user =
      Map.merge(
        user,
        %{name: name, color: String.to_integer(color)}
      )

    {:noreply, assign(socket, user: new_user)}
  end

  def handle_event("submit", %{"user" => %{"color" => color, "name" => name}}, socket) do
    user = socket.assigns.user

    new_user =
      Map.merge(
        user,
        %{name: name, color: String.to_integer(color)}
      )

    {:noreply, assign(socket, user: new_user)}
  end
end
