defmodule PoetryGameWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  def user_hsl(color), do: "color: hsl(#{color}, 70%, 45%);"
end
