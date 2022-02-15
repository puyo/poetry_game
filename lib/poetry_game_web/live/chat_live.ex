defmodule PoetryGame.Live.ChatLive do
  use Phoenix.LiveView,
    container: {:div, class: "chat-live h-full"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  alias PoetryGameWeb.{Endpoint, Presence}

  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col text-black max-w-sm border-l-2 border-stone-300">
      <div class="hidden"><%= @rerender %></div>
      <div class="user-list shrink p-1 bg-stone-100 border-b-4 border-stone-200 border-solid">
        <%= for {id, user} <- Map.to_list(@users) do %>
          <span class="font-semibold" style={"color: #{user_hsl(user.color)}"}><%= user.name %></span>
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
            <p><span class="font-semibold" style={"color: #{user_hsl(color)}"}><%= name %></span>&nbsp;:&nbsp;<%= content %></p>
          <% end %>
        </div>
      </div>
      <div class="entry-form shrink bg-white">
        <form action="#" phx-submit="submit" autocomplete="off">
          <input type="hidden" name="message[user_id]" value={@user_id}>
          <input type="hidden" name="message[user_name]" value={@user_name}>
          <input type="hidden" name="message[color]" value={@user_color}>
          <div class="input-group inline-flex items-center justify-center">
            <span class="shrink p-2">
              <span class="font-semibold" style={"color: #{user_hsl(@user_color)}"}><%= @user_name %></span>&nbsp;:
            </span>
            <input class="w-full grow outline-none py-2" type="text" name="message[content]" value={@message} />
            <button
              class="p-2 shrink font-semibold outline-none focus:bg-amber-200 hover:bg-amber-200"
              type="submit">
                Send
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp user_hsl(color), do: "hsl(#{color}, 70%, 45%)"

  def mount(
        _params,
        %{
          "topic" => topic,
          "user_id" => user_id,
          "user_name" => user_name,
          "user_color" => user_color
        },
        socket
      ) do
    Endpoint.subscribe(topic)
    Endpoint.subscribe("user:#{user_id}")
    Presence.track(self(), topic, user_id, %{id: user_id, name: user_name, color: user_color})

    {
      :ok,
      assign(
        socket,
        user_id: user_id,
        user_name: user_name,
        user_color: user_color,
        topic: topic,
        messages: [],
        message: "",
        rerender: false,
        users: %{}
      )
    }
  end

  def handle_event("submit", %{"message" => message}, %{assigns: %{topic: topic}} = socket) do
    if String.length(message["content"]) > 0 do
      Phoenix.PubSub.broadcast(PoetryGame.PubSub, topic, %{
        event: "chat_message",
        message: message
      })
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

  def handle_event("update-user", %{"user" => %{"color" => color, "name" => name}}, socket) do
    IO.inspect(chat_live: self(), color: color, name: name)
    {:noreply, socket}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{topic: topic}} = socket
      ) do
    {:noreply, assign(socket, users: users(topic))}
  end

  def handle_info(%{event: "chat_message", message: message}, socket) do
    {:noreply, assign(socket, messages: [message | socket.assigns.messages])}
  end

  def handle_info(%{event: "update-user", payload: user}, socket) do
    Presence.update(self(), socket.assigns.topic, user.id, user)

    {:noreply,
     assign(socket,
       user_id: user.id,
       user_name: user.name,
       user_color: user.color,
       users: Map.merge(socket.assigns.users, %{user.id => user})
     )}
  end

  defp users(topic) do
    Presence.list(topic)
    |> Enum.map(fn {id, %{metas: [%{name: name, color: color} | _others]}} ->
      {id, %{name: name, color: color}}
    end)
    |> Enum.into(%{})
  end
end
