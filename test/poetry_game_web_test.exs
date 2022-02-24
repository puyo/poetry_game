defmodule PoetryGameWebTest do
  use PoetryGameWeb.ConnCase, async: true

  alias PoetryGameWebTest.TestController

  defmodule TestController do
    use PoetryGameWeb, :controller
  end

  test "use PoetryGameWeb, :controller imports the right functions" do
    info = Function.info(&TestController.action/2)
    assert Keyword.get(info, :name) == :action
  end
end
