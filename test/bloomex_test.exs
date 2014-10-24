defmodule BloomexTest do
  use ExUnit.Case

  test "scalable add and check membership" do
    bloom = Bloomex.scalable 1000, 0.01, 0.25, 2
    assert Bloomex.member?(bloom, 100) == false

    bloom = Bloomex.add bloom, 100
    assert Bloomex.member?(bloom, 100) == true
  end
end
