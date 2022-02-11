defmodule PoetryGameWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """

  use Phoenix.Presence,
    otp_app: :poetry_game,
    pubsub_server: PoetryGame.PubSub

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(PoetryGame.PubSub, topic, message, __MODULE__)
  end
end
