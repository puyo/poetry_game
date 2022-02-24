defmodule PoetryGame.ApplicationTest do
  use ExUnit.Case, async: true

  alias PoetryGame.Application

  test "start does not raise an exception" do
    assert {:error, {:already_started, _pid}} = Application.start(nil, nil)
  end

  test "config_change does not raise an exception" do
    Application.config_change([], [], [])
  end
end
