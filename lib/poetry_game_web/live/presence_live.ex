defmodule PoetryGame.PresenceLive do
  use PoetryGameWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="presence" class="presence-live bg-slate-50 border-b-2 border-slate-300">
      <div class="container">
        <div class="flex justify-between items-center">
          <a href="/" class="logo justify-start py-2">
            <img src={Routes.static_path(@socket, "/images/poetry-game.svg")} alt="Poetry Game"/>
          </a>
          <div class="current-user justify-end">
            <span><%= @user_name %></span>
            <a href="#" class="p-1"><img src={Routes.static_path(@socket, "/images/quill.svg")} alt="Rename" class="inline"/></a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, %{"user_id" => user_id, "user_name" => user_name}, socket) do
    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:user_name, user_name)

    {:ok, socket}
  end
end
