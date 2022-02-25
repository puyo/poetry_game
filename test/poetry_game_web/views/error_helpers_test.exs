defmodule PoetryGameWeb.ErrorHelpersTest do
  use ExUnit.Case, async: true

  alias PoetryGameWeb.ErrorHelpers

  describe "translate_error/1" do
    test "with no options" do
      assert ErrorHelpers.translate_error({"Hello", []}) == "Hello"
    end

    test "with count" do
      assert ErrorHelpers.translate_error({"Bird", count: 2}) == "Bird"
    end
  end
end
