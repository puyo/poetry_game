defmodule PoetryGame.Live.UserLive do
  use Phoenix.LiveView,
    container: {:div, class: "user-live h-full flex flex-col"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.Endpoint
  alias PoetryGameWeb.Router.Helpers, as: Routes

  def render(assigns) do
    ~H"""
    <div class="h-full bg-stone-300/75 py-20 absolute inset-0" style="z-index: 10000;">
      <form action="#"
        class="shadow overflow-hidden rounded-lg max-w-sm bg-white p-4 mx-auto"
        phx-change="change"
        phx-debounce="200"
        phx-hook="SaveSessionOnSubmit"
        id={"user_form-#{@user.id}"}
      >
        <%= if !@user.name || !@user.color do %>
          <p class="mb-4 text-sm text-slate-500">You will need to set your name before you can join a game.</p>
        <% end %>

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

  def mount(_params, %{"user" => user} = session, socket) do
    {:ok,
     assign(
       socket,
       user: user
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

    {:noreply, assign(socket, user: new_user)}
  end

  def handle_event("show-form", _, socket) do
    {:noreply, assign(socket, show_form: true)}
  end
end
