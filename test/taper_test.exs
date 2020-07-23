defmodule TaperTest do
  use ExUnit.Case
  doctest Taper

  test "greets the world" do
    assert Taper.hello() == :world
  end
end
