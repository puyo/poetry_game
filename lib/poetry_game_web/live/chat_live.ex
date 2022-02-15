defmodule PoetryGame.Live.ChatLive do
  use Phoenix.LiveView,
    container: {:div, class: "chat-live h-full"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.{Endpoint, Presence}

  import PoetryGameWeb.LiveHelpers

  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col text-black max-w-sm border-l-2 border-stone-300">
      <div class="hidden"><%= @rerender %></div>
      <div class="user-list shrink p-1 bg-stone-100 border-b-4 border-stone-200 border-solid">
        <%= for {_id, user} <- Map.to_list(@users) do %>
          <span class="font-semibold" style={user_hsl(user.color)}><%= user.name %></span>
        <% end %>
      </div>
      <div class="messages grow bg-stone-50" style="position: relative;">
        <div id={"scroll-to-bottom-#{@topic}"}
            class="overflow-y-scroll p-1 text-sm border-b-4 border-stone-200 border-solid"
            style="position: absolute; top: 0; left: 0; right: 0; bottom: 0;"
            phx-hook="ScrollToBottomOnInput">
          <%= for message <- Enum.reverse(@messages) do %>
            <% name = message["user_name"] %> <% color = message["color"] %>
            <% content = message["content"] %>
            <p><span class="font-semibold" style={user_hsl(color)}><%= name %></span>&nbsp;:&nbsp;<%= content %></p>
          <% end %>
        </div>
      </div>
      <div class="entry-form shrink bg-white text-sm">
        <form action="#" phx-submit="submit" autocomplete="off">
          <input type="hidden" name="message[user_id]" value={@user.id}>
          <input type="hidden" name="message[user_name]" value={@user.name}>
          <input type="hidden" name="message[color]" value={@user.color}>
          <div class="input-group flex items-center justify-center">
            <div class="grow">
              <input class="w-full outline-none p-2" type="text" name="message[content]" value={@message} />
            </div>
            <div class="shrink">
              <button class="p-2 font-semibold outline-none bg-amber-100 focus:bg-amber-200 hover:bg-amber-200" type="submit">Send</button>
            </div>
          </div>
        </form>
      </div>
    </div>
    """
  end

  def mount(_params, %{"game_id" => game_id, "user" => user}, socket) do
    topic = "chat:#{game_id}"

    # chat messages
    Endpoint.subscribe(topic)

    # all user updates like name/color changes
    Endpoint.subscribe("user:all")

    # user joins/leaves
    Presence.track(self(), topic, user.id, user)

    {
      :ok,
      assign(
        socket,
        user: user,
        topic: topic,
        game_id: game_id,
        messages: [],
        message: "",
        rerender: false,
        users: %{}
      )
    }
  end

  def handle_event("submit", %{"message" => message}, %{assigns: %{topic: topic}} = socket) do
    if String.length(message["content"]) > 0 do
      Endpoint.broadcast(topic, "chat_message", %{message: message})
    end

    {
      :noreply,
      assign(
        socket,
        rerender: !socket.assigns.rerender,
        message: ""
      )
    }
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    IO.inspect(chat_live: socket.assigns.user.name, presence_diff: payload)
    users = users(socket.assigns.topic)
    {:noreply, assign(socket, users: users)}
  end

  def handle_info(%{event: "chat_message", payload: %{message: message}}, socket) do
    {:noreply, assign(socket, messages: [message | socket.assigns.messages])}
  end

  def handle_info(%{event: "update_user", payload: user}, socket) do
    Presence.update(self(), socket.assigns.topic, user.id, user)

    new_user =
      if user.id == socket.assigns.user.id do
        user
      else
        socket.assigns.user
      end

    {:noreply, assign(socket, user: new_user)}
  end

  defp users(topic) do
    Presence.list(topic)
    |> Enum.map(fn {id, %{metas: [%{name: name, color: color} | _others]}} ->
      {id, %{name: name, color: color}}
    end)
    |> Enum.into(%{})
  end
end
