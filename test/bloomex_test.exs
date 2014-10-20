defmodule BloomexTest do
  use ExUnit.Case

  test "bloomex add and check membership" do
    bloom = Bloomex.new 1000, 0.5
    assert Bloomex.member?(bloom, 100) == false

    bloom = Bloomex.add bloom, 100
    assert Bloomex.member?(bloom, 100) == true
  end
end
