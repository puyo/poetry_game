defmodule PoetryGame.PubSub do
  @moduledoc """
  Module to encapsulate functions for working with PubSub.

  PubSub is used to subscribe and send game state updates
  between LiveView processes.
  """

  @spec subscribe_to_game_updates(String.t()) :: String.t()
  def subscribe_to_game_updates(game_id) do
    game_id
    |> game_topic()
    |> PoetryGameWeb.Endpoint.subscribe()

    game_id
  end

  @spec broadcast_game_update!(String.t(), PoetryGame.Game.t()) :: :ok
  def broadcast_game_update!(game_id, game) do
    game_id
    |> game_topic()
    |> PoetryGameWeb.Endpoint.broadcast!("game_state_update", game)
  end

  defp game_topic(game_id), do: "game:#{game_id}"
end
