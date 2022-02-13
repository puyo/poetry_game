defmodule PoetryGame.PresenceLive do
  @moduledoc """
  Connect all users who view this component into one room for chat messages and
  game coordination.
  """

  use PoetryGameWeb, :live_view

  alias PoetryGameWeb.Endpoint

  def render(assigns) do
    ~H"""
    <div id="presence">
    </div>
    """
  end

  def mount(_params, %{"topic" => topic, "user_id" => user_id, "user_name" => user_name}, socket) do
    Endpoint.subscribe(topic)

    {
      :ok,
      assign(
        socket,
        topic: topic,
        user_id: user_id,
        user_name: user_name
      )
    }
  end
end
