defmodule PoetryGame.ChatLive do
  use Phoenix.LiveView,
    container: {:div, class: "h-full"},
    layout: {PoetryGameWeb.LayoutView, "live.html"}

  use Phoenix.HTML

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
            <% name = message["user_name"] %>
            <% color = message["color"] %>
            <% content = message["content"] %>
            <p><span class="font-semibold" style={"color: #{user_hsl(color)}"}><%= name %></span>&nbsp;:&nbsp;<%= content %></p>
          <% end %>
        </div>
      </div>
      <div class="entry-form shrink bg-white">
        <form action="#" phx-submit="submit">
          <%= hidden_input :message, :user_id, value: @user_id  %>
          <%= hidden_input :message, :user_name, value: @user_name  %>
          <%= hidden_input :message, :color, value: @user_color  %>
          <div class="flex items-center justify-center">
            <span class="inline-flex pl-2">
              <span class="font-semibold" style={"color: #{user_hsl(@user_color)}"}><%= @user_name %></span>&nbsp;:&nbsp;
            </span>
            <%= text_input :message, :content, value: @message,
              class: "inline-flex grow focus:border-none outline-none border-none" %>
            <%= submit "Send", class: "inline-flex shrink p-2 font-semibold outline-none focus:bg-amber-200 hover:bg-amber-200" %>
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
    Presence.track(self(), topic, user_id, %{name: user_name, color: user_color})

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

  def handle_info(
        %{event: "presence_diff", payload: payload},
        %{assigns: %{topic: topic}} = socket
      ) do
    # IO.inspect(presence_diff: 1, payload: payload, users: users(topic))

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
    # IO.inspect(message_received: message, recipient: self())

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
