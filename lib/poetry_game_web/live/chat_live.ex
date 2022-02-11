defmodule PoetryGame.ChatLive do
  use Phoenix.LiveView,
    container:
      {:div,
       class:
         "chat-live h-full text-black bg-white max-w-sm border-l-2 border-slate-300 flex flex-col"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  use Phoenix.HTML

  alias PoetryGameWeb.{Endpoint, Presence}

  def render(assigns) do
    ~H"""
    <div class="hidden"><%= @rerender %></div>
    <div class="user-list shrink p-1 bg-slate-100 border-b-2 border-slate-300 border-solid">
      <%= for {id, user} <- Map.to_list(@users) do %>
        <span style={"color: hsl(#{user.color}, 50%, 50%)"}><%= user.name %></span>
      <% end %>
    </div>
    <div class="messages grow text-sm border-b-2 border-slate-300 border-dashed p-1 overflow-y-scroll max-h-[50vh]">
      <%= for message <- Enum.reverse(@messages) do %>
        <% name = message["user_name"] %>
        <% color = message["color"] %>
        <% content = message["content"] %>
        <p><span style={"color: hsl(#{color}, 50%, 50%)"}><%= name %></span>&nbsp;: <%= content %></p>
      <% end %>
    </div>
    <div class="entry-form shrink">
      <form action="#" phx-submit="submit">
        <%= hidden_input :message, :user_id, value: @user_id  %>
        <%= hidden_input :message, :user_name, value: @user_name  %>
        <%= hidden_input :message, :color, value: @user_color  %>
        <div class="flex items-center justify-center rounded-md">
          <%= text_input :message, :content, value: @message, class: "inline-flex grow p-2 focus:border-none outline-none border-none" %>
          <%= submit "Send", class: "inline-flex shrink p-2 hover:bg-slate-300 rounded-md" %>
        </div>
      </form>
    </div>
    """
  end

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
    Presence.track(self(), topic, user_id, %{name: user_name, color: user_color})

    {
      :ok,
      assign(
        socket,
        user_id: user_id,
        user_name: user_name,
        user_color: user_color,
        topic: topic,
        messages: [
          %{
            "color" => 30,
            "content" => String.duplicate("second chat message", 200),
            "user_id" => "123",
            "user_name" => "demo"
          },
          %{
            "color" => user_color,
            "content" => "first chat message",
            "user_id" => user_id,
            "user_name" => user_name
          }
        ],
        message: "",
        rerender: false,
        users: %{}
      )
    }
  end

  def handle_event("submit", %{"message" => message}, %{assigns: %{topic: topic}} = socket) do
    Phoenix.PubSub.broadcast(PoetryGame.PubSub, topic, %{event: "chat_message", message: message})

    {
      :noreply,
      assign(
        socket,
        rerender: !socket.assigns.rerender,
        message: ""
      )
    }
  end

  def handle_info(
        %{event: "presence_diff", payload: payload},
        %{assigns: %{topic: topic}} = socket
      ) do
    IO.inspect(presence_diff: 1, payload: payload, users: users(topic))

    {
      :noreply,
      assign(
        socket,
        users: users(topic)
      )
    }
  end

  def handle_info(
        %{event: "chat_message", message: message},
        %{assigns: %{topic: topic}} = socket
      ) do
    IO.inspect(message_received: message, recipient: self())

    {
      :noreply,
      assign(
        socket,
        messages: [message | socket.assigns.messages]
      )
    }
  end

  defp users(topic) do
    Presence.list(topic)
    |> Enum.map(fn {id, %{metas: [%{name: name, color: color} | _others]}} ->
      {id, %{name: name, color: color}}
    end)
    |> Enum.into(%{})
  end
end
