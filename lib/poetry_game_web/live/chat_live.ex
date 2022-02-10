defmodule PoetryGame.ChatLive do
  use Phoenix.LiveView,
    container:
      {:div,
       class:
         "chat-live h-full text-black bg-slate-50 max-w-sm border-l-2 border-slate-300 p-1 flex flex-col"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  use Phoenix.HTML

  alias PoetryGameWeb.{Endpoint, Presence}

  def render(assigns) do
    ~H"""
    <div class="user-list shrink border-b-2 border-slate-300 border-dashed">
      <%= for {id, user} <- Map.to_list(@users) do %>
        <span style={"color: hsl(#{user.color}, 50%, 50%)"}><%= user.name %></span>
      <% end %>
    </div>
    <div class="messages grow border-b-2 border-slate-300 border-dashed overflow-y-scroll">
      <%= for message <- Enum.reverse(@chat) do %>
        <% name = message["user_name"] %>
        <% color = message["color"] %>
        <% content = message["content"] %>
        <p><span style={"color: hsl(#{color}, 50%, 50%)"}><%= name %></span>&nbsp;: <%= content %></p>
      <% end %>
    </div>
    <div class="entry-form shrink">
      <form action="#" phx-submit="submit">
        <%= text_input :message, :content %>
        <%= hidden_input :message, :user_id, value: @user_id  %>
        <%= hidden_input :message, :user_name, value: @user_name  %>
        <%= hidden_input :message, :color, value: @user_color  %>
        <%= submit "Send" %>
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
        chat: [
          %{
            "color" => 30,
            "content" => "second chat message",
            "user_id" => "123",
            "user_name" => "ruby"
          },
          %{
            "color" => user_color,
            "content" => "first chat message",
            "user_id" => user_id,
            "user_name" => user_name
          }
        ],
        message: "",
        users: %{}
      )
    }
  end

  def handle_event("submit", %{"message" => message_params}, socket) do
    {
      :noreply,
      assign(
        socket,
        chat: [message_params | socket.assigns.chat],
        message: ""
      )
    }
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves} = payload},
        %{assigns: %{topic: topic}} = socket
      ) do
    IO.inspect(payload: payload, users: users(topic))

    {
      :noreply,
      assign(
        socket,
        users: users(topic)
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
